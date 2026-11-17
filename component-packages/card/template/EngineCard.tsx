import type { HTMLAttributes, ReactNode } from 'react'
import settings from './card.config.json'

export type EngineCardProps = HTMLAttributes<HTMLElement> & {
  title?: string
  description?: string
  children?: ReactNode
}

export default function EngineCard({
  title = settings.title,
  description = settings.description,
  children,
  style,
  ...props
}: EngineCardProps) {
  return (
    <section
      {...props}
      style={{
        boxSizing: 'border-box',
        backgroundColor: settings.background,
        color: settings.foreground,
        borderRadius: settings.borderRadius,
        padding: settings.padding,
        boxShadow: settings.shadow
          ? '0 10px 28px rgba(0, 0, 0, 0.15)'
          : 'none',
        ...style,
      }}
    >
      <h2 style={{ margin: 0, fontSize: '1.25rem' }}>{title}</h2>
      <p style={{ margin: '8px 0 0', lineHeight: 1.5 }}>
        {description}
      </p>
      {children && <div style={{ marginTop: 16 }}>{children}</div>}
    </section>
  )
}
