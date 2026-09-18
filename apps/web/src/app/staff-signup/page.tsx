import {redirect} from "next/navigation";

export default function StaffSignupPage(){
  redirect("/staff-login?mode=signup");
}
