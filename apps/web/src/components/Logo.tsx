export function Logo({compact=false}:{compact?:boolean}){
  return <span className={`brand-logo ${compact?"compact":""}`}>
    <img
      src="/brand/heni-logo-blue.webp"
      alt="Heni Maak — هاني معاك"
      width={520}
      height={139}
      draggable={false}
    />
  </span>;
}
