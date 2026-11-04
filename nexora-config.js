exports.handler = async () => {
  const supabaseUrl = process.env.SUPABASE_URL || '';
  const supabaseAnonKey = process.env.SUPABASE_ANON_KEY || process.env.SUPABASE_PUBLISHABLE_KEY || '';
  const validUrl = /^https:\/\/.+\.supabase\.co$/.test(supabaseUrl);
  const validKey = !!supabaseAnonKey && !/service_role|secret/i.test(supabaseAnonKey);
  const body = validUrl && validKey ? { supabaseUrl, supabaseAnonKey } : {};
  return {
    statusCode: 200,
    headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store, max-age=0' },
    body: JSON.stringify(body)
  };
};
