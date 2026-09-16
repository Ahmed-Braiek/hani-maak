"use client";

export function HeniAvatar({
  speaking = false,
  listening = false,
  size = 92,
}: {
  speaking?: boolean;
  listening?: boolean;
  size?: number;
}) {
  return (
    <div
      className={`heni-avatar ${speaking ? "is-speaking" : ""} ${listening ? "is-listening" : ""}`}
      style={{ width: size, height: size }}
      aria-label={speaking ? "Heni is speaking" : listening ? "Heni is listening" : "Heni assistant"}
    >
      <svg viewBox="0 0 120 120" role="img" aria-hidden="true">
        <defs>
          <linearGradient id="heni-bg" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0" stopColor="#dff8f1" />
            <stop offset="1" stopColor="#a6e1d5" />
          </linearGradient>
          <linearGradient id="heni-shirt" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" stopColor="#0f766e" />
            <stop offset="1" stopColor="#075b56" />
          </linearGradient>
          <linearGradient id="heni-skin" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0" stopColor="#e9b58e" />
            <stop offset="1" stopColor="#c9825f" />
          </linearGradient>
          <filter id="heni-shadow" x="-30%" y="-30%" width="160%" height="160%">
            <feDropShadow dx="0" dy="5" stdDeviation="5" floodColor="#0b413b" floodOpacity=".18" />
          </filter>
        </defs>

        <circle cx="60" cy="60" r="57" fill="url(#heni-bg)" />
        <circle className="heni-pulse" cx="60" cy="60" r="54" fill="none" stroke="#0f766e" strokeWidth="2" opacity=".22" />

        <g className="heni-body" filter="url(#heni-shadow)">
          <path d="M24 118c2-24 12-37 36-37s34 13 36 37" fill="url(#heni-shirt)" />
          <path d="M49 84c1 8 4 12 11 12s10-4 11-12" fill="#b96f50" opacity=".55" />
          <path d="M53 78h14v14H53z" fill="url(#heni-skin)" />

          <g className="heni-head">
            <ellipse cx="60" cy="54" rx="29" ry="32" fill="url(#heni-skin)" />
            <path d="M33 51c0-24 12-37 29-37 17 0 28 12 28 31-8-7-14-13-21-13-8 8-18 12-36 13z" fill="#263b39" />
            <path d="M38 44c7-2 18-7 29-17 7 1 14 5 21 13" fill="none" stroke="#405754" strokeWidth="3" strokeLinecap="round" opacity=".55" />
            <ellipse cx="34" cy="57" rx="4" ry="7" fill="#cf8b68" />
            <ellipse cx="86" cy="57" rx="4" ry="7" fill="#cf8b68" />

            <g className="heni-eyes">
              <path d="M44 52c3-3 8-3 11 0" fill="none" stroke="#263b39" strokeWidth="2.2" strokeLinecap="round" />
              <path d="M66 52c3-3 8-3 11 0" fill="none" stroke="#263b39" strokeWidth="2.2" strokeLinecap="round" />
              <ellipse className="heni-eye heni-eye-left" cx="50" cy="56" rx="2.5" ry="3.1" fill="#17312d" />
              <ellipse className="heni-eye heni-eye-right" cx="72" cy="56" rx="2.5" ry="3.1" fill="#17312d" />
            </g>

            <path d="M59 57c-1 5-2 9-1 12 2 1 4 1 6 0" fill="none" stroke="#a76047" strokeWidth="1.5" strokeLinecap="round" />
            <path d="M47 73c7 5 19 5 26 0" fill="#8e493e" opacity=".28" />
            <g className="heni-mouth">
              <path className="heni-mouth-closed" d="M49 74c6 4 16 4 22 0" fill="none" stroke="#7d3f39" strokeWidth="2.4" strokeLinecap="round" />
              <ellipse className="heni-mouth-open" cx="60" cy="75" rx="8" ry="3.3" fill="#6e3938" />
              <path className="heni-teeth" d="M53 74h14" stroke="#fff5ef" strokeWidth="1.3" strokeLinecap="round" />
            </g>
          </g>

          <g className="heni-hand heni-hand-left">
            <path d="M35 98c-11 3-15 10-14 18" fill="none" stroke="#c9825f" strokeWidth="8" strokeLinecap="round" />
          </g>
          <g className="heni-hand heni-hand-right">
            <path d="M85 98c9 3 14 10 14 18" fill="none" stroke="#c9825f" strokeWidth="8" strokeLinecap="round" />
          </g>
        </g>

        <g opacity=".95">
          <circle cx="91" cy="91" r="14" fill="#fff" />
          <path d="M84 91h14M91 84v14" stroke="#0f766e" strokeWidth="3" strokeLinecap="round" />
        </g>
      </svg>
      <span className="heni-status-dot" />
    </div>
  );
}
