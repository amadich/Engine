import type { ButtonHTMLAttributes } from 'react'

type EngineButtonProps = ButtonHTMLAttributes<HTMLButtonElement>

export default function EngineButton({
  children = 'Engine Button',
  type = 'button',
  style,
  ...props
}: EngineButtonProps) {
  return (
    <button
      {...props}
      type={type}
      style={{
        padding: '10px 16px',
        border: '1px solid #818cf8',
        borderRadius: '8px',
        backgroundColor: '#4338ca',
        color: '#fff',
        cursor: 'pointer',
        ...style,
      }}
    >
      {children}
    </button>
  )
}
