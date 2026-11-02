# supabase-stack

The repo behind Aether's "time to a working dev stack" benchmark: the local Supabase stack (Postgres, PostgREST, GoTrue, Realtime, Storage, Studio, Inbucket) plus one Node app on port 3000 whose `/health` answers only once it has queried Postgres through the stack.

The same repo is configured in every product under test with that product's own startup hooks, so a new workspace is "ready" when `hooks/probe.sh` succeeds:

```sh
curl -sf http://127.0.0.1:3000/health   # {"db":"ok","now":"...","tables":...}
```

| product | where the hooks live | what runs |
|---|---|---|
| Aether | `.aether/environment.json` | setup `npm ci`; image prewarm into the seed; terminals `npx supabase start` and `npm run dev` |
| Replicas | `replicas.json` | warm hook caches the images into the snapshot; start hook runs `hooks/start.sh` on every start |
| Conductor Cloud | Settings → Cloud computer (the repo file is ignored there) | install script `hooks/conductor-install.sh`; repository setup script `hooks/conductor-setup.sh` |

`hooks/start.sh` is idempotent: it starts the stack, starts the app if it is not answering, and waits for `/health`.

`tools/bench/vm_bench.py` is the in-sandbox workload the benchmark's `vm` scenario runs: ripgrep over the tree, reading every file, a Node CPU loop, `git status`, a 256 MB fsynced write.

The harness is `tools/bench/bench.py` in [Aether-Runtime/aether](https://github.com/Aether-Runtime/aether).
