/**
 * Development-only KidZone demo seed.
 *
 * Uses the Firebase CLI login already on this machine. It does not create
 * Auth users and it does not store Admin credentials.
 *
 *   firebase login
 *   node tools/seed_demo_data/seed.js
 *   node tools/seed_demo_data/seed.js --reset
 *
 * Safe to run again. Documents use fixed ids, so a second run overwrites
 * the same demo records instead of duplicating them.
 */
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const PROJECT = 'kidzone-56c7d';
const SEED_KEY = 'kidzone-viva-demo';
const RESET = process.argv.includes('--reset');

const PAIRS = [
  {
    label: 'Pair 1',
    parentEmail: 'arhamwhoo@gmail.com',
    childEmail: 'saifsalmani@gmail.com',
    parentUid: 'LSvkcfvQvJXXVWO2EzqUGXuZK2y2',
    childUid: 'LzVwPSdWjMYT1P0frcMReMaPe3k1',
    childKey: 'saif',
    location: { latitude: 19.07609, longitude: 72.877426, accuracy: 12 },
    screen: {
      totalMinutes: 84,
      apps: [
        ['com.google.android.youtube', 'YouTube', 32],
        ['com.android.chrome', 'Chrome', 21],
        ['com.kidzone.learn', 'Educational App', 18],
        ['other', 'Other', 13],
      ],
    },
    points: 240,
    level: 3,
    achievements: ['firstActivity', 'firstGame', 'hundredPoints', 'perfectQuiz'],
    wallet: { balance: 750, allowance: 250, pocket: 500 },
    games: [
      ['math_quiz', 8, 9],
      ['spelling_quiz', 10, 10],
      ['knowledge_quiz', 7, 8],
    ],
    activities: [
      ['maths', 'Mathematics Homework', 'homework', true, '16:00', '17:00'],
      ['exercise', 'Morning Exercise', 'exercise', true, '07:00', '07:30'],
      ['reading', 'English Reading', 'learning', false, '18:00', '18:30'],
      ['science', 'Science Assignment', 'homework', false, '19:00', '19:45'],
      ['bedtime', 'Bedtime', 'sleep', false, '21:00', '21:30'],
    ],
    messages: [
      ['1', 'parent', "Don't forget your mathematics homework"],
      ['2', 'child', "Okay, I'll finish it before dinner."],
      ['3', 'parent', 'Great job on your quiz!'],
    ],
    reminders: [
      ['maths', 'Mathematics Homework', '16:30'],
      ['reading', 'English Reading', '18:00'],
      ['bedtime', 'Bedtime', '21:00'],
    ],
  },
  {
    label: 'Pair 2',
    parentEmail: 'arhamkhan@gmail.com',
    childEmail: 'gang@gmail.com',
    parentUid: 'aeGQ9AhEaJdIN9UTQLcKZgmjMGG3',
    childUid: 'bVooROigERQydWwuTM6xnjnRnLd2',
    childKey: 'gang',
    location: { latitude: 28.613939, longitude: 77.209023, accuracy: 18 },
    screen: {
      totalMinutes: 67,
      apps: [
        ['com.google.android.youtube', 'YouTube', 20],
        ['com.android.chrome', 'Chrome', 16],
        ['com.kidzone.learn', 'Educational App', 21],
        ['other', 'Other', 10],
      ],
    },
    points: 190,
    level: 2,
    achievements: ['firstActivity', 'firstGame', 'hundredPoints'],
    wallet: { balance: 500, allowance: 200, pocket: 300 },
    games: [
      ['math_quiz', 7, 8],
      ['spelling_quiz', 9, 9],
      ['knowledge_quiz', 8, 9],
    ],
    activities: [
      ['physics', 'Physics Revision', 'learning', true, '16:00', '17:00'],
      ['walk', 'Evening Walk', 'exercise', true, '17:30', '18:00'],
      ['reading', 'English Reading', 'learning', false, '18:15', '18:45'],
      ['computer', 'Computer Practice', 'homework', false, '19:00', '19:40'],
      ['bedtime', 'Bedtime', 'sleep', false, '21:15', '21:45'],
    ],
    messages: [
      ['1', 'parent', 'Remember to finish your computer practice today.'],
      ['2', 'child', "Okay, I'll do it."],
      ['3', 'parent', 'Good luck with your revision!'],
    ],
    reminders: [
      ['physics', 'Physics Revision', '16:00'],
      ['computer', 'Computer Practice', '19:00'],
      ['bedtime', 'Bedtime', '21:15'],
    ],
  },
];

function firebaseLib() {
  const bin = execFileSync('which', ['firebase'], { encoding: 'utf8' }).trim();
  return path.resolve(path.dirname(fs.realpathSync(bin)), '..');
}

function field(value) {
  if (value === null || value === undefined) return { nullValue: null };
  if (typeof value === 'string') return { stringValue: value };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'number') {
    if (Number.isInteger(value)) return { integerValue: String(value) };
    return { doubleValue: value };
  }
  if (value instanceof Date) return { timestampValue: value.toISOString() };
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map(field) } };
  }
  if (typeof value === 'object' && value.kind === 'map') {
    const fields = {};
    for (const [key, item] of Object.entries(value.fields)) fields[key] = field(item);
    return { mapValue: { fields } };
  }
  throw new Error(`Cannot encode ${value}`);
}

function fieldsOf(data) {
  const fields = {};
  for (const [key, value] of Object.entries(data)) fields[key] = field(value);
  return fields;
}

function readValue(raw) {
  if (!raw) return null;
  if ('stringValue' in raw) return raw.stringValue;
  if ('booleanValue' in raw) return raw.booleanValue;
  if ('integerValue' in raw) return Number(raw.integerValue);
  if ('doubleValue' in raw) return raw.doubleValue;
  if ('timestampValue' in raw) return raw.timestampValue;
  if ('nullValue' in raw) return null;
  if ('arrayValue' in raw) return (raw.arrayValue.values || []).map(readValue);
  if ('mapValue' in raw) {
    const out = {};
    for (const [key, value] of Object.entries(raw.mapValue.fields || {})) {
      out[key] = readValue(value);
    }
    return out;
  }
  return null;
}

function readDoc(doc) {
  const out = {};
  for (const [key, value] of Object.entries((doc && doc.fields) || {})) {
    out[key] = readValue(value);
  }
  return out;
}

function dateKey(date) {
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${date.getFullYear()}-${month}-${day}`;
}

function startOfLocalDay(offsetDays) {
  const date = new Date();
  date.setDate(date.getDate() + offsetDays);
  date.setHours(0, 0, 0, 0);
  return date;
}

function weekPeriod(date) {
  const monday = new Date(date);
  monday.setHours(12, 0, 0, 0);
  monday.setDate(date.getDate() - ((date.getDay() + 6) % 7));
  return `w-${dateKey(monday)}`;
}

function docName(parts) {
  return `projects/${PROJECT}/databases/(default)/documents/${parts.join('/')}`;
}

async function main() {
  const lib = firebaseLib();
  const auth = require(path.join(lib, 'auth.js'));
  const { requireAuth } = require(path.join(lib, 'requireAuth.js'));
  const { Client } = require(path.join(lib, 'apiv2.js'));
  const account = auth.getGlobalDefaultAccount();
  if (!account) {
    throw new Error('Not logged in. Run `firebase login` and try again.');
  }
  await requireAuth({
    project: PROJECT,
    projectId: PROJECT,
    tokens: account.tokens,
    user: account.user,
  });
  const client = new Client({
    urlPrefix: 'https://firestore.googleapis.com',
    apiVersion: 'v1',
  });

  async function getDoc(parts) {
    try {
      const res = await client.get(`/${docName(parts)}`);
      return readDoc(res.body);
    } catch (error) {
      if (error.status === 404) return null;
      throw error;
    }
  }

  async function commit(writes) {
    if (!writes.length) return;
    for (let i = 0; i < writes.length; i += 400) {
      await client.post(
        `/projects/${PROJECT}/databases/(default)/documents:commit`,
        { writes: writes.slice(i, i + 400) },
      );
    }
  }

  function upsert(parts, data) {
    return {
      update: {
        name: docName(parts),
        fields: fieldsOf({ ...data, seedKey: SEED_KEY }),
      },
    };
  }

  const today = startOfLocalDay(0);
  const now = new Date();
  const families = [];

  for (const pair of PAIRS) {
    const parent = await getDoc(['users', pair.parentUid]);
    const child = await getDoc(['users', pair.childUid]);
    if (!parent || !child) {
      throw new Error(
        `${pair.label} is missing a Firestore profile. No Auth account was created.`,
      );
    }
    const parentEmail = String(parent.email || '').toLowerCase();
    const childEmail = String(child.email || '').toLowerCase();
    if (parentEmail !== pair.parentEmail || childEmail !== pair.childEmail) {
      throw new Error(
        `${pair.label} email mismatch. Expected ${pair.parentEmail} / ${pair.childEmail}, found ${parent.email} / ${child.email}.`,
      );
    }
    if (!parent.familyId || parent.familyId !== child.familyId) {
      throw new Error(
        `${pair.label} is not in the same family. Parent familyId=${parent.familyId || 'none'}, child familyId=${child.familyId || 'none'}. No Auth account was created.`,
      );
    }
    if (parent.role !== 'parent' || child.role !== 'child') {
      throw new Error(
        `${pair.label} roles are ${parent.role} and ${child.role}. Expected parent and child.`,
      );
    }
    const family = await getDoc(['families', parent.familyId]);
    if (!family || family.parentId !== pair.parentUid) {
      throw new Error(
        `${pair.label} family ${parent.familyId} is not owned by ${pair.parentEmail}.`,
      );
    }
    const childRecord = await getDoc([
      'families',
      parent.familyId,
      'children',
      pair.childUid,
    ]);
    if (!childRecord) {
      throw new Error(
        `${pair.label} child ${pair.childEmail} is not listed in family ${parent.familyId}.`,
      );
    }
    families.push({ pair, parent, child, familyId: parent.familyId, family });
    console.log(
      JSON.stringify({
        pair: pair.label,
        parentEmail: parent.email,
        parentUid: pair.parentUid,
        parentName: parent.name,
        childEmail: child.email,
        childUid: pair.childUid,
        childName: child.name,
        familyId: parent.familyId,
        familyName: family.familyName || null,
        linked: true,
      }),
    );
  }

  if (new Set(families.map((item) => item.familyId)).size !== families.length) {
    throw new Error('The two pairs share a family id. Seeding was stopped.');
  }

  if (RESET) {
    const writes = [];
    for (const item of families) {
      const { pair, familyId } = item;
      const ids = [
        ...pair.activities.map((row) => ['families', familyId, 'activities', `demo_${pair.childKey}_${row[0]}`]),
        ['families', familyId, 'locations', pair.childUid],
        ['families', familyId, 'screenTime', pair.childUid],
        ...pair.games.map((row) => ['families', familyId, 'gameProgress', `${pair.childUid}_${row[0]}`]),
        ['families', familyId, 'points', pair.childUid],
        ['families', familyId, 'wallets', pair.childUid],
        ['families', familyId, 'wallets', pair.childUid, 'transactions', `demo_${pair.childKey}_pocket`],
        ['families', familyId, 'wallets', pair.childUid, 'transactions', `demo_${pair.childKey}_allowance`],
        ...pair.messages.map((row) => ['families', familyId, 'messages', `demo_${pair.childKey}_msg_${row[0]}`]),
        ...pair.reminders.map((row) => ['families', familyId, 'reminders', `demo_${pair.childKey}_${row[0]}`]),
      ];
      for (const parts of ids) {
        const existing = await getDoc(parts);
        if (existing && existing.seedKey === SEED_KEY) {
          writes.push({ delete: docName(parts) });
        }
      }
    }
    await commit(writes);
    console.log(JSON.stringify({ reset: true, deleted: writes.length }));
    return;
  }

  const writes = [];
  const counts = [];
  for (const item of families) {
    const { pair, familyId, parent } = item;
    let created = 0;
    const touch = (parts, data) => {
      writes.push(upsert(parts, data));
      created += 1;
    };

    for (const [id, title, type, completed, start, end] of pair.activities) {
      touch(['families', familyId, 'activities', `demo_${pair.childKey}_${id}`], {
        activityId: `demo_${pair.childKey}_${id}`,
        childId: pair.childUid,
        title,
        description: title,
        type,
        scheduledDate: today,
        startTime: start,
        endTime: end,
        completed,
        pointsAwarded: false,
        createdBy: pair.parentUid,
        createdAt: now,
        ...(completed ? { completedAt: now } : {}),
      });
    }

    touch(['families', familyId, 'locations', pair.childUid], {
      locationId: pair.childUid,
      childId: pair.childUid,
      latitude: pair.location.latitude,
      longitude: pair.location.longitude,
      accuracy: pair.location.accuracy,
      timestamp: now,
      sharingEnabled: false,
      source: 'demo',
      isDemo: true,
    });

    touch(['families', familyId, 'screenTime', pair.childUid], {
      recordId: pair.childUid,
      childId: pair.childUid,
      date: dateKey(today),
      totalMinutes: pair.screen.totalMinutes,
      dailyLimitMinutes: 120,
      appUsage: pair.screen.apps.map(([packageName, appName, minutes]) => ({
        kind: 'map',
        fields: { packageName, appName, name: appName, minutes },
      })),
      updatedAt: now,
      source: 'demo',
      isDemo: true,
    });

    for (const [gameId, score, bestScore] of pair.games) {
      touch(
        ['families', familyId, 'gameProgress', `${pair.childUid}_${gameId}`],
        {
          progressId: `${pair.childUid}_${gameId}`,
          childId: pair.childUid,
          gameId,
          score,
          bestScore,
          completed: true,
          lastPlayed: now,
          updatedAt: now,
        },
      );
    }

    touch(['families', familyId, 'points', pair.childUid], {
      childId: pair.childUid,
      points: pair.points,
      level: pair.level,
      updatedAt: now,
      achievements: pair.achievements,
    });

    touch(['families', familyId, 'wallets', pair.childUid], {
      childId: pair.childUid,
      balance: pair.wallet.balance,
      allowanceAmount: pair.wallet.allowance,
      allowanceFrequency: 'weekly',
      lastAllowancePeriod: weekPeriod(today),
      updatedAt: now,
    });
    touch(
      ['families', familyId, 'wallets', pair.childUid, 'transactions', `demo_${pair.childKey}_pocket`],
      {
        transactionId: `demo_${pair.childKey}_pocket`,
        type: 'pocket_money',
        amount: pair.wallet.pocket,
        note: 'Pocket money',
        createdBy: pair.parentUid,
        createdAt: new Date(now.getTime() - 2 * 60 * 60 * 1000),
      },
    );
    touch(
      ['families', familyId, 'wallets', pair.childUid, 'transactions', `demo_${pair.childKey}_allowance`],
      {
        transactionId: `demo_${pair.childKey}_allowance`,
        type: 'allowance',
        amount: pair.wallet.allowance,
        note: 'Weekly allowance',
        createdBy: pair.parentUid,
        createdAt: new Date(now.getTime() - 60 * 60 * 1000),
      },
    );

    pair.messages.forEach((row, index) => {
      const [id, who, text] = row;
      const fromParent = who === 'parent';
      const sentAt = new Date(now.getTime() - (pair.messages.length - index) * 60 * 1000);
      touch(['families', familyId, 'messages', `demo_${pair.childKey}_msg_${id}`], {
        messageId: `demo_${pair.childKey}_msg_${id}`,
        senderId: fromParent ? pair.parentUid : pair.childUid,
        receiverId: fromParent ? pair.childUid : pair.parentUid,
        text,
        createdAt: sentAt,
        clientCreatedAt: sentAt,
        read: false,
      });
    });

    for (const [id, title, time] of pair.reminders) {
      touch(['families', familyId, 'reminders', `demo_${pair.childKey}_${id}`], {
        reminderId: `demo_${pair.childKey}_${id}`,
        childId: pair.childUid,
        title,
        description: title,
        date: dateKey(today),
        time,
        enabled: true,
        createdBy: pair.parentUid,
        createdAt: now,
        completed: false,
      });
    }

    writes.push({
      update: {
        name: docName(['users', pair.childUid]),
        fields: fieldsOf({ dailyScreenLimitMinutes: 120 }),
      },
      updateMask: { fieldPaths: ['dailyScreenLimitMinutes'] },
    });

    counts.push({
      familyId,
      parent: parent.email,
      child: pair.childEmail,
      records: created,
    });
  }

  await commit(writes);

  for (const item of families) {
    const activities = await client.get(
      `/${docName(['families', item.familyId, 'activities'])}`,
    );
    const titles = ((activities.body.documents || []))
      .map((doc) => readDoc(doc).title)
      .filter(Boolean);
    console.log(
      JSON.stringify({
        verifyFamily: item.familyId,
        child: item.child.email,
        activityTitles: titles,
      }),
    );
  }
  console.log(JSON.stringify({ seeded: true, counts }));
}

main().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
