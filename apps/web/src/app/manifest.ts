import type {MetadataRoute} from "next";

export default function manifest():MetadataRoute.Manifest{
  return {
    name:"Heni Maak — هاني معاك",
    short_name:"Heni Maak",
    description:"Patient journey infrastructure: access, guidance and continuity.",
    start_url:"/patient",
    display:"standalone",
    background_color:"#f5f9ff",
    theme_color:"#0849b4",
    icons:[{src:"/hani-icon.svg",sizes:"any",type:"image/svg+xml",purpose:"any"}]
  };
}
