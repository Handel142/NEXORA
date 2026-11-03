# Security notes

- Never commit Supabase service-role keys, database passwords, TURN shared secrets, or other server-side credentials.
- The browser app may contain a Supabase project URL and public anon/publishable key. These are public values; Row Level Security (RLS), restricted RPC grants, and server-side validation must enforce access.
- Voice chat requests microphone permission only after a player chooses to join voice. Audio is not recorded by this application.
- Use HTTPS for deployment and microphone access.
- Configure TURN with short-lived credentials from a trusted provider; do not place a long-lived TURN secret in `backend/config.js`.
- Review database policies and SQL functions before production use. The included local tests do not replace a security review or real multi-device test.
