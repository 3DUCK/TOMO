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
export const generateDailyQuote = functions.pubsub.schedule("0 0 * * *")
  .timeZone("Asia/Seoul") // 중요: 한국 시간대(KST)를 명시적으로 설정
  .onRun(async (context: functions.EventContext) => {
    // context 변수를 사용하지 않을 경우, ESLint 경고를 제거하기 위해 _context로 변경하는 것을 고려할 수 있습니다.
    // async (_context: functions.EventContext) => {

    const now = new Date();
    // KST로 변환
    const kst = new Date(now.getTime() + 9 * 60 * 60 * 1000);
    const year = kst.getFullYear();
    const month = (kst.getMonth() + 1).toString().padStart(2, "0");
    const day = kst.getDate().toString().padStart(2, "0");
    const docId = `${year}-${month}-${day}`;

    console.log(`Generating daily quotes for ${docId}...`);

    // 4가지 주제별 프롬프트
    const topics = [
      {
        key: "employment",
        prompt:
          "취업을 준비하는 사람들에게 영감을 주는 짧고 " +
          "간결한 문구 하나를 생성해줘. 불필요한 설명 없이 문구만 생성해줘.",
      },
      {
        key: "diet",
        prompt:
          "다이어트를 하는 사람들에게 동기부여가 되는 짧고 " +
          "간결한 문구 하나를 생성해줘. 불필요한 설명 없이 문구만 생성해줘.",
      },
      {
        key: "selfdev",
        prompt:
          "자기계발을 하는 사람들에게 힘이 되는 짧고 " +
          "간결한 문구 하나를 생성해줘. 불필요한 설명 없이 문구만 생성해줘.",
      },
      {
        key: "study",
        prompt:
          "학업에 열중하는 사람들에게 응원이 되는 짧고 " +
          "간결한 문구 하나를 생성해줘. 불필요한 설명 없이 문구만 생성해줘.",
      },
    ];

    const results: Record<string, string> = {};
    try {
      for (const topic of topics) {
        const chatCompletion = await openai.chat.completions.create({
          model: "gpt-3.5-turbo",
          messages: [{role: "user", content: topic.prompt}],
          temperature: 0.7,
          max_tokens: 50,
        });
        results[topic.key] =
          chatCompletion.choices[0].message?.content?.trim() ||
          "문구를 생성하지 못했습니다.";
      }
      // Firestore에 저장
      const quoteRef = db.collection("dailyQuotes").doc(docId);
      await quoteRef.set({
        ...results,
        date: admin.firestore.Timestamp.fromDate(kst),
        generatedBy: "OpenAI",
        style: "영감적",
      });
      console.log(
        `Successfully generated and saved daily quotes for ${docId}`
      );
      return null;
    } catch (error) {
      console.error(
        `Error generating or saving daily quotes for ${docId}:`,
        error
      );
      return null;
    }
  });
