import cors from "@elysiajs/cors";
import openapi from "@elysiajs/openapi";
import staticPlugin from "@elysiajs/static";
import { Elysia, file } from "elysia";
import logixlysia from "logixlysia";

const v1 = new Elysia({ prefix: "/api/v1" })
  .use(
    cors({
      origin: (process.env.STATEFUL_DOMAINS as unknown as string)
        .split(",")
        .map((d) => d.trim()),
      credentials: true,
      allowedHeaders: ["Content-Type", "Authorization"],
    })
  )
  .get("/", () => {
    return { message: "Hello Elysia" };
  });

const filesApi = new Elysia()
  .use(staticPlugin({ prefix: "/public", assets: "public" }))
  .get("/favicon.ico", file("public/favicon.ico"))
  .get(
    "/.well-known/appspecific/com.chrome.devtools.json",
    file("public/.well-known/appspecific/com.chrome.devtools.json")
  );

const log = logixlysia({
  config: {
    pino: {
      level: "silent",
    },
    showStartupMessage: true,
    startupMessageFormat: "simple",
    timestamp: {
      translateTime: "yyyy-mm-dd HH:MM:ss",
    },
    ip: true,
    logFilePath: "./logs/runtime.log",
    logRotation: {
      maxSize: "10m",
      interval: "1d",
      maxFiles: "7d",
      compress: true,
    },
    customLogFormat:
      "{now} {level} {duration} {method} {pathname} {status} {message} {ip} {epoch}",
    logFilter: {},
  },
});

const app = new Elysia()
  .use(log)
  .use(openapi())
  .use(filesApi)
  .use(v1)
  .listen(process.env.PORT ?? 3000);

export type App = typeof app;
