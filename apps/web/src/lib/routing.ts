import type { FacilityEdge, FacilityNode } from "./types";
export interface RouteResult { nodeIds:string[]; nodes:FacilityNode[]; edges:FacilityEdge[]; distanceM:number; }
export function shortestRoute(nodes:FacilityNode[], edges:FacilityEdge[], from:string, to:string, accessibleOnly=false):RouteResult {
  const nodeMap=new Map(nodes.map(n=>[n.id,n])); if(!nodeMap.has(from)||!nodeMap.has(to)) throw new Error("Unknown route node");
  const adj=new Map<string,{to:string;edge:FacilityEdge}[]>();
  for(const edge of edges){ if(edge.restricted || (accessibleOnly&&!edge.accessible)) continue; const push=(a:string,b:string)=>{const x=adj.get(a)??[];x.push({to:b,edge});adj.set(a,x)}; push(edge.from,edge.to); if(edge.bidirectional) push(edge.to,edge.from); }
  const dist=new Map<string,number>([[from,0]]), prev=new Map<string,{node:string;edge:FacilityEdge}>(), open=new Set<string>([from]);
  while(open.size){ let u="";let best=Infinity; for(const n of open){const d=dist.get(n)??Infinity;if(d<best){best=d;u=n}} open.delete(u); if(u===to) break;
    for(const next of adj.get(u)??[]){const alt=best+next.edge.distanceM;if(alt<(dist.get(next.to)??Infinity)){dist.set(next.to,alt);prev.set(next.to,{node:u,edge:next.edge});open.add(next.to)}}
  }
  if(!dist.has(to)) throw new Error("No valid route found"); const nodeIds=[to], routeEdges:FacilityEdge[]=[]; let cur=to;
  while(cur!==from){const p=prev.get(cur); if(!p) throw new Error("Route reconstruction failed");routeEdges.unshift(p.edge);cur=p.node;nodeIds.unshift(cur)}
  return {nodeIds,nodes:nodeIds.map(id=>nodeMap.get(id)!),edges:routeEdges,distanceM:dist.get(to)!};
}
