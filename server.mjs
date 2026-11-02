// The app under test: one HTTP server whose /health answers only when Postgres behind the Supabase stack answers.
import http from "node:http";
import pg from "pg";

const port = Number(process.env.PORT ?? 3000);
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL ?? "postgresql://postgres:postgres@127.0.0.1:54322/postgres" });

const server = http.createServer(async (request, response) => {
  if (request.url !== "/health") {
    response.writeHead(404).end();
    return;
  }
  try {
    const { rows } = await pool.query("select now() as now, count(*)::int as tables from information_schema.tables");
    response.writeHead(200, { "content-type": "application/json" });
    response.end(JSON.stringify({ db: "ok", now: rows[0].now, tables: rows[0].tables }));
  } catch (error) {
    response.writeHead(503, { "content-type": "application/json" });
    response.end(JSON.stringify({ db: "down", error: String(error.message ?? error) }));
  }
});

server.listen(port, "127.0.0.1", () => {
  console.log(`listening on http://127.0.0.1:${port}`);
});
