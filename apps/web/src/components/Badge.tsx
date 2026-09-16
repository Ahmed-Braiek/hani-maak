export function Badge({children,tone=""}:{children:React.ReactNode;tone?:""|"good"|"warn"|"danger"|"info"}){return <span className={`badge ${tone}`}>{children}</span>}
