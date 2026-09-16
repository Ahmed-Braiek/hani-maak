import {NextResponse} from "next/server";import {mutateDb} from "@/lib/db";
export async function POST(){const result=await mutateDb(db=>{let count=0;for(const n of db.notifications){if(n.state==="queued"){n.state="simulated";count++}}return{count}});return NextResponse.json({...result,note:"Competition mode marks queued reminders as simulated. External sending is opt-in."})}
