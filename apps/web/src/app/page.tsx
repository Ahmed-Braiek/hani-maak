import { redirect } from "next/navigation";

// Production Flutter shell entry; backend APIs live in the same Next.js project.

export default function Landing() {
  redirect("/flutter/index.html");
}
