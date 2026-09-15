# Fan Engagement Platform

> Freelance project, originally built as "Mida Music V1".

**English summary** — A gamified fan-engagement platform that connects to fans'
Spotify and YouTube accounts and turns listening activity into competition:

- OAuth connection to Spotify and YouTube with automatic data sync (top artists, recently played, liked music videos);
- points engine: listening time and monthly per-artist bonuses on Spotify; likes and music-channel subscriptions on YouTube;
- per-artist leaderboards refreshed hourly by background jobs;
- daily missions and seasonal rewards (tickets, merchandise).

Built with Ruby on Rails, OmniAuth (Spotify/YouTube), and PostgreSQL. Full
documentation below is in Portuguese.

---

## Descrição Geral
Este é um projeto Ruby on Rails que integra Spotify e YouTube para monitorar atividades musicais dos usuários, permitindo um sistema de gamificação com leaderboards e recompensas. Usuários podem se engajar com seus artistas favoritos, acumular pontos e competir por prêmios sazonais.

## Funcionalidades Principais

### Integração com Spotify e YouTube
- Conexão única com as contas de Spotify e YouTube, com sincronização automática de dados.
- Dados extraídos: artistas mais escutados (Spotify) e vídeos de música curtidos (YouTube).

### Sistema de Pontuação e Leaderboards
- **Spotify**: Pontos com base em tempo de escuta (10 pontos por minuto e 100 pontos de bônus por artista ao mês).
- **YouTube**: Pontos para curtidas (40 por vídeo) e assinaturas de canais musicais (100 pontos, uma vez).
- Leaderboards por artista, atualizados uma vez por hora.

### Missões Diárias e Recompensas
- Missões incentivam ações diárias para ganho extra de pontos.
- Recompensas sazonais para os melhores do leaderboard: ingressos, merchandise e outros prêmios.

## Principais Controladores e Rotas
- **ProfilesController**
   - `show`: Exibe interações do usuário, artistas favoritos e leaderboard.
   - `fetch_user_top_artists_spotify` e `fetch_user_recently_played_youtube`: Atualizam a pontuação a partir dos dados de cada serviço.
   - `fetch_and_process_liked_videos`: Atribui pontos para vídeos de música curtidos no YouTube.

## Configuração e Login
- Autenticação inicial única para Spotify e YouTube. Dados são sincronizados automaticamente.
