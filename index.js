import { readFileSync, existsSync } from 'fs';
import { join } from 'path';

const SESSION_FILE = join(process.env.HOME || process.env.USERPROFILE || '', '.zapless', 'session.json');
const SERVER_URL = process.env.ZAPLESS_SERVER || 'https://api.t31k.cloud';

function getSession() {
  if (!existsSync(SESSION_FILE)) return null;
  try {
    return JSON.parse(readFileSync(SESSION_FILE, 'utf-8'));
  } catch {
    return null;
  }
}

async function fetchSkill(token) {
  const res = await fetch(`${SERVER_URL}/api/zapless/skill?token=${encodeURIComponent(token)}&mode=plugin`);
  if (!res.ok) throw new Error(`Server returned ${res.status}`);
  return res.text();
}

export default {
  id: 'zapless',
  name: 'Zapless',
  description: 'OAuth management for your agents — Gmail, GitHub, Slack, Notion and more.',
  kind: 'lifecycle',

  register(api) {
    api.on('before_agent_start', async (_event, _ctx) => {
      const session = getSession();

      if (!session) {
        return {
          appendSystemContext:
            '[Zapless] Not authenticated. Run: zapless onboard',
        };
      }

      try {
        const skill = await fetchSkill(session.install_token);
        return { appendSystemContext: skill };
      } catch {
        return {
          appendSystemContext:
            '[Zapless] Could not fetch skill instructions. Run: zapless doctor to diagnose.',
        };
      }
    });
  },
};
