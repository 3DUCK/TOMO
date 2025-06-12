import * as functions from "firebase-functions/v1"; // v1 명시적 임포트 유지
import * as admin from "firebase-admin";
import OpenAI from "openai";

// Firebase Admin SDK 초기화
admin.initializeApp();
const db = admin.firestore(); // Firestore 인스턴스

// OpenAI API 키를 환경 변수에서 불러옵니다.
const OPENAI_API_KEY = functions.config().openai.api_key;
const openai = new OpenAI({apiKey: OPENAI_API_KEY}); // OpenAI 클라이언트 초기화

// 매일 특정 시간에 실행될 Cloud Function
// Cloud Scheduler를 사용하여 매일 자정(KST)에 실행되도록 스케줄링합니다.
// KST 00:00은 UTC 15:00이므로, '0 15 * * *' 크론 표현식과 함께 timeZone 설정
export const generateDailyQuote = functions.pubsub.schedule("0 15 * * *")
  .timeZone("Asia/Seoul") // 중요: 한국 시간대(KST)를 명시적으로 설정
  .onRun(async (context: functions.EventContext) => {
    // context 변수를 사용하지 않을 경우, ESLint 경고를 제거하기 위해 _context로 변경하는 것을 고려할 수 있습니다.
    // async (_context: functions.EventContext) => {

    const today = new Date();
    // 날짜를 YYYY-MM-DD 형식으로 포맷 (Firestore 문서 ID로 사용)
    const year = today.getFullYear();
    const month = (today.getMonth() + 1).toString().padStart(2, "0");
    const day = today.getDate().toString().padStart(2, "0");
    const docId = `${year}-${month}-${day}`;

    console.log(`Generating daily quote for ${docId}...`);

    try {
      // 1. OpenAI API 호출하여 문구 생성 (max-len 오류 해결을 위해 줄바꿈)
      const prompt = "오늘 하루를 시작하는 사람들에게 영감을 주고, " +
                "긍정적인 메시지를 전달하는 짧고 간결한 문구 하나를 생성해줘." +
               "불필요한 서론이나 부연 설명 없이, 문구 자체만 생성해줘." +
               "예를 들어, '오늘 당신의 노력이 내일의 당신을 만듭니다.' 와 같이.";

      // OpenAI API 호출
      const chatCompletion = await openai.chat.completions.create({
        model: "gpt-3.5-turbo", // 또는 'gpt-4o', 'gpt-4-turbo' 등 원하는 모델 사용
        messages: [{role: "user", content: prompt}],
        temperature: 0.7, // 창의성 조절 (0.0~1.0)
        max_tokens: 50, // 문구 길이 제한
      });

      const quoteText = chatCompletion.choices[0]
        .message?.content?.trim() || "문구를 생성하지 못했습니다.";
      const generatedBy = "OpenAI";

      // 2. Firestore dailyQuotes 컬렉션에 저장
      const quoteRef = db.collection("dailyQuotes").doc(docId);
      await quoteRef.set({
        text: quoteText,
        date: admin.firestore.Timestamp.fromDate(today), // 서버 시간으로 타임스탬프 저장
        generatedBy: generatedBy,
        style: "영감적", // 필요에 따라 스타일 값 설정
      });

      console.log("Successfully generated and saved " + // max-len 오류 해결을 위해 줄바꿈
        `quote for ${docId}: "${quoteText}"`);
      return null; // 성공적으로 완료되었음을 알림
    } catch (error) {
      console.error(`Error generating or saving quote for ${docId}:`, error);
      // 오류가 발생해도 함수가 성공적으로 완료된 것으로 처리하여 재시도 루프 방지
      return null;
    }
  });
