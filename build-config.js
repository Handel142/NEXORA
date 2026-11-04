const fs = require('fs');
const url = process.env.SUPABASE_URL || '';
const key = process.env.SUPABASE_ANON_KEY || process.env.SUPABASE_PUBLISHABLE_KEY || '';
const validUrl = /^https:\/\/.+\.supabase\.co$/.test(url);
const validKey = !!key && !/service_role|secret/i.test(key);
const config = validUrl && validKey ? { supabaseUrl: url, supabaseAnonKey: key } : {};
fs.writeFileSync('backend/runtime-config.js', 'window.NEXORA_CONFIG = Object.assign(window.NEXORA_CONFIG || {}, ' + JSON.stringify(config) + ');\n');
console.log(validUrl && validKey ? 'NEXORA public Supabase config generated.' : 'NEXORA runtime config is empty; add SUPABASE_URL and SUPABASE_ANON_KEY in Netlify.');
