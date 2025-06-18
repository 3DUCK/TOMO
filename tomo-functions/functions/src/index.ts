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
          "취업 준비생을 위한 짧고 강력한 동기 부여 문구를 1개만 생성하는데, " +
          "불확실성을 극복하고, 성장하며, 기회를 잡는다는 긍정적인 메시지를 담아주고, " +
          "문구 앞뒤에 인용 부호(\")를 붙이지 말고," +
          "문구는 꼭 20자 이하로 작성해주고, 아래 예시 참고해줘" +
          "예: '도전은 최고의 이력서.' 또는 '실패 없는 성공은 없다'",
      },
      {
        key: "diet",
        prompt:
          "다이어트 중인 사람들에게 활력과 자신감을 불어넣는 짧고 간결한 문구를 1개만 생성하는데, " +
          "건강한 습관, 긍정적인 변화, 꾸준함의 중요성을 강조해주고, " +
          "문구 앞뒤에 인용 부호(\")를 붙이지 말고," +
          "문구는 20자 이하로 작성해주고, 아래 예시 참고해줘" +
          "예: '운동하러가라' 또는 '네 몸에게 미안하지 않니?'",
      },
      {
        key: "selfdev",
        prompt:
          "자기계발을 통해 성장하려는 사람들에게 영감을 주는 짧고 통찰력 있는 문구를 1개만 생성하는데, " +
          "배움의 즐거움, 잠재력 발현, 삶의 질 향상을 나타내주고, " +
          "문구 앞뒤에 인용 부호(\")를 붙이지 말고," +
          "조금 강하게 말해도 좋고," +
          "문구는 20자 이하로 작성해주고, 아래 예시 참고해줘" +
          "예: '할 일을 다 하지 못하면 자지 마라' 또는 '쇼츠 그만 봐라'",
      },
      {
        key: "study",
        prompt:
          "학업에 매진하는 학생들에게 집중과 성취를 독려하는 짧고 희망찬 문구를 1개만 생성하는데, " +
          "지식의 가치, 노력의 결실, 미래를 위한 투자를 암시해주고, " +
          "문구 앞뒤에 인용 부호(\")를 붙이지 말고," +
          "문구는 20자 이하로 작성해주고, 아래 예시 참고해줘" +
          "예: '지식은 가장 밝은 빛.' 또는 '열심히 하지 말고 그냥 하세요'",
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
