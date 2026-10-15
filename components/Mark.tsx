import { useId } from "react";
// Tombstone mark on CleanShotX blue (the same gradient the old capture glyph tile used). Original art.
// The gradient id is per-instance: a shared id resolves to the first copy in the DOM, which can sit inside a hidden layout and then nothing paints.
export const Mark = ({ size = 28 }: { size?: number }) => {
  const id = useId();
  return <svg width={size} height={size} viewBox="0 0 32 32" aria-hidden="true">
    <defs><linearGradient id={id} x1="0" y1="0" x2="1" y2="1"><stop offset="0" stopColor="#3aa6ff" /><stop offset=".6" stopColor="#0b5bff" /><stop offset="1" stopColor="#6a3dff" /></linearGradient></defs>
    <rect width="32" height="32" rx="8" fill={`url(#${id})`} />
    <g fill="#fff"><path d="M16 5.5a8 8 0 0 1 8 8V24H8V13.5a8 8 0 0 1 8-8z" /><rect x="5" y="23" width="22" height="4.5" rx="1.6" /></g>
    <path d="M12.2 11.8l7.6 7.6M19.8 11.8l-7.6 7.6" stroke="#0b5bff" strokeWidth="2.6" strokeLinecap="round" fill="none" />
  </svg>;
};
