const fs = require('fs');
const bcrypt = require('bcryptjs');
const config = require('../config/env');
const { dbManager, EMPTY_STORE } = require('../config/db');
const { MongoDBRepository } = require('../adapters/MongoDBRepository');
const { PineconeVectorAdapter, KB_FILE } = require('../adapters/PineconeVectorAdapter');
const { Models } = require('../models/schemas');

const SEED_FAQS = [
  {
    faqId: 'faq_exam_01',
    category: 'Examinations',
    question: 'When do Odd Semester End-Term Examinations begin at Amity University Rajasthan?',
    answerText: 'Odd Semester End-Term Theory Examinations for B.Tech CSE begin on December 4, 2026, following Practical & Lab Viva-Voce assessments (including BCS 522 Software Engineering Lab) from November 23 to November 30, 2026.'
  },
  {
    faqId: 'faq_exam_02',
    category: 'Examinations',
    question: 'What is the minimum attendance required to appear in End-Semester Exams?',
    answerText: 'Students must maintain a minimum of 75% attendance in each course (Theory and Lab separately) to be eligible for End-Semester Examinations. Medical condonation up to 5% requires Chief Proctor and Dean approval.'
  },
  {
    faqId: 'faq_exam_03',
    category: 'Examinations',
    question: 'How can I download my Admit Card for semester examinations?',
    answerText: 'Admit Cards are released on the Amizone Student Portal 7 days prior to the first exam after clearance of semester fees and no-dues verification.'
  },
  {
    faqId: 'faq_fee_01',
    category: 'Fees & Finance',
    question: 'What is the annual tuition fee for B.Tech Computer Science & Engineering (CSE)?',
    answerText: 'The non-sponsored academic tuition fee for B.Tech CSE at Amity University Rajasthan (Jaipur) is INR 1,86,000 per semester (INR 3,72,000 per academic year), payable via Amizone online portal or Demand Draft.'
  },
  {
    faqId: 'faq_fee_02',
    category: 'Fees & Finance',
    question: 'What is the deadline and late fee policy for semester fee payment?',
    answerText: 'Semester fees must be deposited within 15 days of semester commencement. A late fee of INR 500 per week applies thereafter up to 4 weeks.'
  },
  {
    faqId: 'faq_hostel_01',
    category: 'Hostel & Campus',
    question: 'What are the hostel fees and room options at Amity University Rajasthan?',
    answerText: 'On-campus AC Triple-Sharing Hostel fee is INR 1,10,000 per year and Non-AC Triple-Sharing is INR 75,000 per year (excluding mess charges of INR 48,000/year). Wi-Fi, 24x7 security, and infirmary are included.'
  },
  {
    faqId: 'faq_hostel_02',
    category: 'Hostel & Campus',
    question: 'What are the campus transport bus routes from Jaipur city?',
    answerText: 'University AC buses operate daily from Vaishali Nagar, Mansarovar, Raja Park, Malviya Nagar, and Vidhyadhar Nagar to the Kant Kalwar (NH-11C) campus. Annual transport fee is INR 34,000.'
  },
  {
    faqId: 'faq_adm_01',
    category: 'Admissions',
    question: 'What is the eligibility criteria for admission to B.Tech CSE?',
    answerText: 'Candidates require a minimum of 60% aggregate in Class XII with Physics, Mathematics, and Chemistry/Computer Science, along with a valid JEE Main / Amity JEE score and personal interview.'
  },
  {
    faqId: 'faq_adm_02',
    category: 'Admissions',
    question: 'How do I apply for admissions at Amity University Rajasthan?',
    answerText: 'Applications are submitted online at amity.edu/jaipur with an application fee of INR 1,500, followed by online document upload and Selection Process interview slot booking.'
  },
  {
    faqId: 'faq_schol_01',
    category: 'Scholarships',
    question: 'What merit scholarships are offered to B.Tech students?',
    answerText: 'Amity offers 100% tuition scholarship for 93%+ aggregate in Class XII (CBSE/ISC), 50% scholarship for 88%-92.99%, and 25% scholarship for 80%-87.99% or JEE Main 90+ percentile.'
  },
  {
    faqId: 'faq_schol_02',
    category: 'Scholarships',
    question: 'How is merit scholarship renewed in subsequent years?',
    answerText: 'Continuation of 100% scholarship requires ranking in the top 5% of the merit list (minimum 8.5 CGPA), and 50% scholarship requires top 10% (minimum 8.0 CGPA) without any backlogs.'
  },
  {
    faqId: 'faq_tt_01',
    category: 'Timetable & Labs',
    question: 'What are the regular class timings and Software Engineering Lab (BCS 522) schedule?',
    answerText: 'Regular academic classes run Monday to Friday from 9:15 AM to 5:05 PM (each lecture 55 minutes). B.Tech CSE 5th Semester Software Engineering Lab (BCS 522) is held in ASET Block-B Lab-204 on Tuesdays and Thursdays.'
  },
  {
    faqId: 'faq_tt_02',
    category: 'Timetable & Labs',
    question: 'Where can I view my updated section-wise weekly timetable?',
    answerText: 'Section-wise weekly timetables, faculty room allocations, and elective slots are published under the "My Timetable" tab on Amizone and on the ASET Department Notice Board.'
  },
  {
    faqId: 'faq_lib_01',
    category: 'Library & IT',
    question: 'What are the Central Library operating hours and digital journal access rules?',
    answerText: 'The AUR Central Library is open from 8:30 AM to 9:00 PM on weekdays and 9:00 AM to 5:00 PM on Saturdays. IEEE Xplore, ACM Digital Library, and SpringerLink are accessible on campus Wi-Fi and via remote VPN.'
  },
  {
    faqId: 'faq_lib_02',
    category: 'Library & IT',
    question: 'How do students reset their Amizone or campus Wi-Fi password?',
    answerText: 'Use the "Forgot Password" OTP link on amizone.net using your registered mobile number, or visit the IT Helpdesk on the Ground Floor of Block-A with your university ID card.'
  },
  {
    faqId: 'faq_place_01',
    category: 'Placements',
    question: 'When do campus placement drives start for B.Tech CSE students?',
    answerText: 'Pre-placement training by Amity Technical Placement Centre (ATPC) starts in Semester 6, and core campus recruitment drives commence from July of Semester 7.'
  },
  {
    faqId: 'faq_place_02',
    category: 'Placements',
    question: 'What is the minimum CGPA required to sit for ATPC placement drives?',
    answerText: 'Students with a cumulative CGPA of 6.5 and above with zero active backlogs are eligible for Tier-1 and core IT placement drives coordinated by ATPC.'
  },
  {
    faqId: 'faq_doc_01',
    category: 'Student Services',
    question: 'How do I apply for a Bonafide Certificate or Official Transcript?',
    answerText: 'Submit an online request under "Student Services -> Certificates" on Amizone. Bonafide certificates are issued within 2 working days and official transcripts within 5 working days.'
  },
  {
    faqId: 'faq_anti_01',
    category: 'Campus Policies',
    question: 'Who do I contact for anti-ragging or campus grievance redressal?',
    answerText: 'Amity University Rajasthan enforces a zero-tolerance anti-ragging policy. Students can reach the 24x7 Anti-Ragging Helpline at 1800-180-5522 or email proctor@jpr.amity.edu.'
  },
  {
    faqId: 'faq_event_01',
    category: 'Events & Clubs',
    question: 'When is Odyssey, the annual techno-cultural fest of Amity University Rajasthan?',
    answerText: 'Odyssey, the flagship annual techno-cultural fest of AUR, is scheduled for February 18-20, 2027, featuring hackathons, robotics challenges, and cultural nights.'
  }
];

const SEED_DOCUMENTS = [
  {
    docId: 'doc_cir_exams_2026',
    title: 'Circular AUR/COE/2026/114 - Odd Semester Examination Guidelines',
    category: 'Circular',
    content: 'Controller of Examinations Notice: Practical exams including BCS 522 Software Engineering Lab will be conducted from Nov 23 to Nov 30, 2026. Theory exams start Dec 4, 2026 in Morning (9:30 AM - 12:30 PM) and Afternoon (2:00 PM - 5:00 PM) shifts. Scientific calculators are permitted only where specified on the question paper.'
  },
  {
    docId: 'doc_fee_struct_2026',
    title: 'AUR Fee Structure Notification 2026-27 (ASET B.Tech Programs)',
    category: 'Fee Structure',
    content: 'Amity School of Engineering & Technology (ASET) Jaipur Fee Schedule: B.Tech CSE semester fee is INR 1,86,000. One-time refundable academic security deposit is INR 20,000 at admission. International students fee is USD 3,100 per semester.'
  },
  {
    docId: 'doc_bcs522_syllabus',
    title: 'BCS 522 Software Engineering Lab Manual & Evaluation Rubric',
    category: 'Timetable & Labs',
    content: 'Course BCS 522 Software Engineering Lab (Credits: 2) covers SRS documentation (IEEE 830), UML Class/Sequence/Use-Case modeling, layered architecture implementation, automated unit/integration testing, and traceability matrix verification. Continuous evaluation carries 60 marks and End-Term Lab Viva carries 40 marks.'
  },
  {
    docId: 'doc_hostel_rules_26',
    title: 'Residential Hostel & Mess Rules Handbook 2026',
    category: 'Hostel & Campus',
    content: 'All hostellers must mark biometric attendance by 9:30 PM daily. Out-pass requests for weekend home visits require parent SMS confirmation through the Amizone Hostel Portal at least 24 hours in advance.'
  },
  {
    docId: 'doc_schol_policy_26',
    title: 'Amity Merit & Sports Scholarship Policy 2026-27',
    category: 'Scholarships',
    content: 'Fast-track direct admission without entrance test is granted to students securing 80%+ in Class XII CBSE/ISC. Merit scholarships (100%, 50%, 25%) are awarded automatically on first-year tuition fees upon document verification.'
  }
];

async function seedMongoOnly(repo) {
  const dbUri = repo.dbUri;
  const now = new Date().toISOString();

  const adminHash = bcrypt.hashSync('Admin@123', 10);
  const sysAdminHash = bcrypt.hashSync('SysAdmin@123', 10);
  const studentHash = bcrypt.hashSync('Student@123', 10);

  const safeInsert = async (collectionKey, pkField, ModelClass, doc, fks = []) => {
    try {
      await repo.insertRecord(collectionKey, pkField, ModelClass, doc, fks);
    } catch (err) {
      if (err && err.code === 'DUPLICATE_PRIMARY_KEY') return;
      throw err;
    }
  };

  await safeInsert('adminStaff', 'staffId', Models.AdminStaff, {
    staffId: 'staff_aur_01',
    dbUri,
    indexName: config.pineconeIndex,
    role: 'admin_staff',
    username: 'admin_aur',
    name: 'Dr. Kavita Sharma (ASET Coordinator)',
    passwordHash: adminHash
  });

  await safeInsert(
    'systemAdmins',
    'adminId',
    Models.SystemAdministrator,
    {
      adminId: 'sysadmin_aur_01',
      staffId: 'staff_aur_01',
      apiEndpoint: '/api/sysadmin',
      role: 'system_admin',
      username: 'sysadmin_aur',
      name: 'Rajesh Rathore (IT Infrastructure Lead)',
      passwordHash: sysAdminHash
    },
    [{ field: 'staffId', targetCollection: 'adminStaff', targetField: 'staffId' }]
  );

  await safeInsert('students', 'userId', Models.Student, {
    userId: 'stu_a50105224001',
    preferredLanguage: 'en',
    isAuthenticated: true,
    name: 'Aarav Verma',
    email: 'aarav.verma@s.amity.edu',
    enrollmentNo: 'A50105224001',
    program: 'B.Tech CSE (Sem 5 - BCS 522)',
    semester: 5,
    role: 'student',
    passwordHash: studentHash
  });

  await safeInsert('students', 'userId', Models.Student, {
    userId: 'stu_a50105224002',
    preferredLanguage: 'hi',
    isAuthenticated: true,
    name: 'Priya Meena',
    email: 'priya.meena@s.amity.edu',
    enrollmentNo: 'A50105224002',
    program: 'B.Tech CSE (Sem 5 - BCS 522)',
    semester: 5,
    role: 'student',
    passwordHash: studentHash
  });

  await repo.ensureStudentAndWidget('stu_a50105224001', 'en', true, 'Aarav Verma');
  await repo.ensureStudentAndWidget('stu_a50105224002', 'hi', true, 'Priya Meena');

  for (const faq of SEED_FAQS) {
    await safeInsert('smartFaqs', 'faqId', Models.SmartFAQ, {
      faqId: faq.faqId,
      dbUri,
      question: faq.question,
      answerText: faq.answerText,
      category: faq.category,
      lastUpdated: now
    });
  }

  const serviceConfigs = [
    {
      configId: 'JWT_AUTH_SERVICE',
      serviceName: 'JWT_AUTH_SERVICE',
      supportedLanguages: ['en', 'hi', 'mr', 'ta', 'bn', 'pa'],
      rateLimitMax: 120,
      rateLimitWindowMs: 60000,
      apiEndpoint: '/api/auth',
      maskedSecretHint: '***MASKED***',
      updatedAt: now
    },
    {
      configId: 'MONGODB_REPOSITORY',
      serviceName: 'MONGODB_REPOSITORY',
      dbUri,
      apiEndpoint: 'internal://mongodb-repository',
      maskedSecretHint: '***MASKED***',
      updatedAt: now
    },
    {
      configId: 'PINECONE_VECTOR_DB',
      serviceName: 'PINECONE_VECTOR_DB',
      indexName: config.pineconeIndex,
      apiEndpoint: 'https://api.pinecone.io',
      maskedSecretHint: '***MASKED***',
      updatedAt: now
    },
    {
      configId: 'PINECONE_VECTOR_ADAPTER',
      serviceName: 'PINECONE_VECTOR_ADAPTER',
      indexName: config.pineconeIndex,
      apiEndpoint: 'internal://pinecone-vector-adapter',
      maskedSecretHint: '***MASKED***',
      updatedAt: now
    },
    {
      configId: 'AI_TRANSLATION_SERVICE',
      serviceName: 'AI_TRANSLATION_SERVICE',
      supportedLanguages: ['en', 'hi', 'mr', 'ta', 'bn', 'pa'],
      apiEndpoint: 'https://generativelanguage.googleapis.com',
      maskedSecretHint: '***MASKED***',
      updatedAt: now
    }
  ];

  for (const cfg of serviceConfigs) {
    await safeInsert('serviceConfigs', 'configId', Models.ServiceConfig, cfg);
  }

  const sampleLogs = [
    {
      logId: 'lg_seed_01',
      dbUri,
      sessionId: 'sess_demo_aur_01',
      userId: 'stu_a50105224001',
      queryText: 'When do Odd Semester End-Term Examinations begin at Amity University Rajasthan?',
      responseText: 'Based on official Amity University Rajasthan records: Odd Semester End-Term Theory Examinations for B.Tech CSE begin on December 4, 2026, following Practical & Lab Viva-Voce assessments (including BCS 522 Software Engineering Lab) from November 23 to November 30, 2026.',
      language: 'en',
      timestamp: new Date(Date.now() - 3600000).toISOString()
    },
    {
      logId: 'lg_seed_02',
      dbUri,
      sessionId: 'sess_demo_aur_02',
      userId: 'stu_a50105224002',
      queryText: 'à¤¬à¥€.à¤Ÿà¥‡à¤• à¤¸à¥€à¤à¤¸à¤ˆ à¤•à¥€ à¤«à¥€à¤¸ à¤•à¤¿à¤¤à¤¨à¥€ à¤¹à¥ˆ?',
      responseText: '[à¤¹à¤¿à¤¨à¥à¤¦à¥€ à¤…à¤¨à¥à¤µà¤¾à¤¦] à¤à¤®à¤¿à¤Ÿà¥€ à¤µà¤¿à¤¶à¥à¤µà¤µà¤¿à¤¦à¥à¤¯à¤¾à¤²à¤¯ à¤°à¤¾à¤œà¤¸à¥à¤¥à¤¾à¤¨ à¤•à¥‡ à¤†à¤§à¤¿à¤•à¤¾à¤°à¤¿à¤• à¤°à¤¿à¤•à¥‰à¤°à¥à¤¡ à¤•à¥‡ à¤…à¤¨à¥à¤¸à¤¾à¤°: The non-sponsored academic tuition fee for B.Tech CSE at Amity University Rajasthan (Jaipur) is INR 1,86,000 per semester (INR 3,72,000 per academic year).',
      language: 'hi',
      timestamp: new Date(Date.now() - 1800000).toISOString()
    }
  ];

  for (const lg of sampleLogs) {
    await safeInsert('sessionLogs', 'logId', Models.SessionLog, lg);
  }

  dbManager.saveToDisk();
}

async function seedPineconeOnly(pinecone) {
  const now = new Date().toISOString();
  if (config.mockMode) {
    pinecone.documents = SEED_DOCUMENTS.map((d) => ({
      ...d,
      updatedAt: now
    }));
    pinecone.saveDocuments();
    return;
  }

  if (config.pineconeApiKey) {
    for (const d of SEED_DOCUMENTS) {
      await pinecone.upsertDocument({
        docId: d.docId,
        title: d.title,
        category: d.category,
        content: d.content
      });
    }
  }
}

async function runSeed({ forceReset = true } = {}) {
  if (!dbManager.connected) {
    await dbManager.connect();
  }

  if (forceReset && config.mockMode) {
    dbManager.store = JSON.parse(JSON.stringify(EMPTY_STORE));
  }

  const repo = new MongoDBRepository();
  const pinecone = new PineconeVectorAdapter();

  await seedMongoOnly(repo);
  await seedPineconeOnly(pinecone);

  return {
    faqsCount: SEED_FAQS.length,
    docsCount: SEED_DOCUMENTS.length,
    studentsCount: 2
  };
}

async function seedDatabaseIfEmpty() {
  if (!dbManager.connected) {
    await dbManager.connect();
  }

  if (config.mockMode) {
    if (dbManager.store.smartFaqs.length === 0) {
      return runSeed({ forceReset: true });
    }
    return {
      faqsCount: dbManager.store.smartFaqs.length,
      docsCount: fs.existsSync(KB_FILE) ? JSON.parse(fs.readFileSync(KB_FILE, 'utf8')).length : 0,
      studentsCount: dbManager.store.students.length
    };
  }

  const repo = new MongoDBRepository();
  const pinecone = new PineconeVectorAdapter();

  const existingFaqs = await Models.SmartFAQ.countDocuments();
  const existingAdmins = await Models.AdminStaff.countDocuments();
  if (existingFaqs === 0 || existingAdmins === 0) {
    await seedMongoOnly(repo);
  }

  if (config.pineconeApiKey) {
    const vectorCount = await pinecone.getLiveVectorCount();
    if (vectorCount === 0) {
      await seedPineconeOnly(pinecone);
    }
  }

  return {
    faqsCount: await Models.SmartFAQ.countDocuments(),
    docsCount: SEED_DOCUMENTS.length,
    studentsCount: await Models.Student.countDocuments()
  };
}

if (require.main === module) {
  runSeed({ forceReset: config.mockMode })
    .then((summary) => {
      console.log('[AskUni Seed] Completed successfully:', JSON.stringify(summary));
      process.exit(0);
    })
    .catch((err) => {
      console.error('[AskUni Seed] Failed:', err);
      process.exit(1);
    });
}

module.exports = { runSeed, seedDatabaseIfEmpty, SEED_FAQS, SEED_DOCUMENTS };