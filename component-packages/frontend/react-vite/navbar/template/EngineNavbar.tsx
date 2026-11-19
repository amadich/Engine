import type { CSSProperties } from 'react'
import settings from './navbar.config.json'

const links = [
  { label: 'Home', href: '/' },
  { label: 'About', href: '#about' },
  { label: 'Contact', href: '#contact' },
]

export default function EngineNavbar() {
  const style: CSSProperties = {
    boxSizing: 'border-box',
    width: `${settings.widthPercent}%`,
    minHeight: settings.minHeight,
    marginInline: 'auto',
    padding: '10px 20px',
    display: 'flex',
    flexWrap: 'wrap',
    alignItems: 'center',
    gap: 20,
    backgroundColor: settings.background,
    color: settings.foreground,
    position: settings.placement === 'sticky' ? 'sticky' : 'static',
    top: settings.placement === 'sticky' ? 0 : undefined,
    zIndex: settings.placement === 'sticky' ? 10 : undefined,
  }

  return (
    <nav aria-label="Main navigation" style={style}>
      <strong>{settings.brand}</strong>

      <div style={{
        display: 'flex',
        flex: '1 1 auto',
        flexWrap: 'wrap',
        gap: 16,
        justifyContent: settings.alignment === 'center'
          ? 'center'
          : `flex-${settings.alignment}`,
      }}>
        {links.map(link => (
          <a key={link.href} href={link.href} style={{ color: 'inherit' }}>
            {link.label}
          </a>
        ))}
      </div>
    </nav>
  )
}