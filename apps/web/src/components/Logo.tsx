export function Logo({compact=false}:{compact?:boolean}){
  return <span className={`brand-logo ${compact?"compact":""}`}>
    <img
      src="/brand/heni-logo-blue-v2.webp"
      alt="Heni Maak — هاني معاك"
      width={640}
      height={170}
      decoding="async"
      draggable={false}
    />
  </span>;
}
