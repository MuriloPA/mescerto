// Configuração do Supabase.
//
// Onde achar: painel do Supabase > Project Settings > API.
//   * supabaseUrl     -> "Project URL"
//   * supabaseAnonKey -> chave PÚBLICA ("anon" ou "publishable")
//
// ATENÇÃO: use SOMENTE a chave pública. NUNCA coloque aqui a chave
// "service_role" / "secret": ela dá acesso total ao banco e qualquer pessoa
// consegue extraí-la do APK. A segurança dos dados vem do RLS no banco.
const supabaseUrl = 'https://ogkdhazgfytponhofrpb.supabase.co';
const supabaseAnonKey = 'sb_publishable_nZWTQb2zLyXeZ2gfrjtMVw_nxwf_fN6';
