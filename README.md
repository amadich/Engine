<h1>
  <img
    src="https://github.com/user-attachments/assets/5cf0abc4-170e-4a4b-aa39-d060c3a7747f"
    alt="JeridiEngine Logo"
    width="64"
    height="64"
    align="absmiddle"
  />
  JeridiEngine
</h1>

### A Modular Visual Development Workspace for Modern Software Projects

**Explore. Build. Inspect. Organize.**

JeridiEngine is a desktop development environment built with **C++, Qt 6, and QML**, designed to bring project exploration, reusable component management, source inspection, and development workflows into one unified workspace.

The project explores a simple but ambitious idea:

> What if developers could understand, organize, and manage complex software projects through an extensible visual environment, without losing access to the underlying source code?

Rather than replacing traditional development tools, JeridiEngine aims to provide an additional layer of structure, visibility, and control over modern software projects.

**Current Version:** `v0.7.0`  
**Development Status:** Active Development  
**Primary Platform:** macOS  
**Technology:** C++ / Qt Quick / QML / CMake  
**Repository:** https://github.com/amadich/Engine

---
<img width="1486" height="921" alt="image" src="https://github.com/user-attachments/assets/e6d5d0bf-315f-4ad0-a0c0-170e1a4d7ee4" />


## 01. Overview

Modern software development involves more than writing code.

A single application may contain hundreds of components, dependencies, configuration files, assets, services, and architectural layers.

As projects grow, developers must constantly navigate between different tools to understand how everything fits together.

JeridiEngine is designed to address this challenge by introducing a modular, panel-based workspace that brings together:

- Project exploration and file navigation
- Reusable component libraries
- Component configuration and inspection
- Source code viewing and editing
- Package and technology organization
- Development output monitoring
- Project previews
- Customizable workspace layouts

The long-term goal is to create a development environment where software architecture and implementation can be explored through both visual interfaces and source code.

---

## 02. Project Philosophy

JeridiEngine is built around five core principles.

### Modularity

Features should be implemented as independent modules rather than tightly coupled components.

A change to the Component Library should not require rewriting the Project Explorer or Inspector.

### Extensibility

The architecture should support new component types, inspectors, project technologies, and workspace tools without continuously expanding a single central controller.

### Maintainability

Clear responsibilities, reusable UI elements, and organized source directories are essential.

A development environment must remain understandable as its codebase grows.

### Developer Control

Visual tooling should complement source code rather than hide it.

Developers should be able to inspect project files, understand component configuration, and maintain control over their projects.

### Technology Independence

The long-term vision is to support different application architectures and technology stacks through adaptable project models and component definitions.

---

## 03. Application Workspace

The JeridiEngine interface uses a multi-panel desktop layout inspired by professional development environments.

### Workspace Layout

The workspace is organized into dockable functional areas.

| Workspace Area | Responsibility |
|---|---|
| Component Library | Discover and manage reusable components |
| Project Explorer | Navigate project files and directories |
| Inspector | Examine and configure selected items |
| Source Editor | View and edit source files |
| Live Preview | Display available project or component previews |
| Output Console | Monitor development activity and messages |
| Workspace Manager | Organize panels and working areas |

The objective is to keep frequently used development tools accessible without forcing developers to switch between unrelated windows.

### Flexible Panel System

The workspace is designed around configurable panels.

Supported interface concepts include:

- Multiple panels within one workspace
- Left, right, and central working regions
- Panel visibility controls
- Expandable and collapsible sections
- Panel ordering and workspace layouts
- Context-sensitive information displays

This structure creates a foundation for additional development tools in future versions.

---

## 04. Component Library

The Component Library is one of the central features of JeridiEngine.

Its purpose is to organize reusable software components into a structured, searchable catalog.

### Component Organization

Components can be grouped according to their role within an application.

For example:

```text
Component Library
│
├── Frontend
│   ├── Collaboration
│   │   ├── Chat History
│   │   ├── Friend Requests
│   │   └── Online Members
│   │
│   ├── Display
│   ├── Feedback
│   ├── Forms
│   └── Navigation
│
└── Backend
    ├── API
    ├── Authentication
    ├── Data
    └── Services
```

This tree illustrates the intended classification model. Available categories depend on the connected project and component catalog.

### Component Discovery

The library interface includes:

- Searchable component entries
- Hierarchical categories
- Component metadata
- Installation status indicators
- Package details
- Component file information
- Technology and dependency information

### Component Lifecycle

JeridiEngine introduces a distinction between components available in the library and components installed within a project.

The component management workflow is intended to cover:

1. Discover a component.
2. Inspect its details.
3. Review its files and dependencies.
4. Install or integrate it into a project.
5. Configure supported properties.
6. Maintain or remove the component when necessary.

Project-changing operations should be explicit and require appropriate confirmation.

---

## 05. Component Inspector

The Inspector provides a context-sensitive interface for examining selected components and project resources.

Instead of displaying the same controls for every selection, the Inspector is designed to adapt to the selected item.

### Component Information

Depending on the selected component, the Inspector may display:

- Component name and description
- Package identifier
- Installation state
- Technology information
- Configurable properties
- Integration details
- Package contents
- Project installation location
- Available management actions

### Property Configuration

The goal is to move beyond generic property editors.

Different property types should receive appropriate controls.

Examples include:

| Property Type | Intended Control |
|---|---|
| Text | Text input |
| Boolean | Toggle or checkbox |
| Number | Numeric input |
| Enumeration | Select menu |
| Color | Color selector |
| File path | File selection control |
| Array | Repeatable item editor |
| Object | Nested property editor |

The long-term objective is a schema-driven Inspector that can render configuration interfaces based on component metadata.

This would allow new components to introduce their own properties without requiring a separate hardcoded Inspector for every component.

---

## 06. Project Explorer

The Project Explorer provides visibility into the structure of a connected software project.

It helps developers navigate directories, locate resources, and understand how application files are organized.

### Features

- Hierarchical project navigation
- File and directory exploration
- Search and filtering
- File-type categorization
- Resource discovery
- Selection-based inspection
- Integration with the source editor

### Project Awareness

JeridiEngine aims to recognize different kinds of resources, including:

- Source code
- Configuration files
- Images and media
- Component definitions
- Package manifests
- Application assets

The Project Explorer serves as a bridge between the physical project directory and the visual development workspace.

---

## 07. Source Editor

JeridiEngine includes a source editing workspace for interacting with project files.

The current interface demonstrates source inspection for TypeScript and React projects.

### Editor Capabilities

The editor interface includes:

- File tabs
- Line numbers
- Syntax highlighting
- File status information
- Source navigation
- Import references
- Code outline
- File metadata

### Source Intelligence

The interface provides dedicated views for source-file references and structural information.

For example, a React file may contain:

```tsx
import React, { useState } from "react";
import Dashboard from "./pages/Dashboard";
import Profile from "./pages/Profile";
```

JeridiEngine aims to help developers distinguish local project references from external package dependencies.

Future development may expand this into deeper source analysis, symbol navigation, and language-aware tooling.

---

## 08. Live Preview

The Live Preview panel provides a dedicated workspace area for displaying project or component previews.

Its purpose is to connect source inspection and component configuration with visual feedback.

### Preview Objectives

- Display supported component previews
- Provide a dedicated preview area
- Keep preview tools accessible alongside the editor
- Support future integration with project development servers
- Enable richer visual feedback during component configuration

Live Preview is an evolving part of the application.

It should not currently be interpreted as a complete replacement for browser-based debugging or frontend development servers.

---

## 09. Output Console

The Output Console provides a centralized location for development-related messages.

It helps developers understand what is happening inside the application and connected projects.

### Console Interface

The console includes concepts such as:

- Timestamped messages
- Message categories
- Search and filtering
- Status indicators
- Output controls
- Project activity reporting

Example output:

```text
[ENGINE] Jeridi Engine ready.
[ENGINE] Project opened.
[INFO] Project resources discovered.
[INFO] Component catalog loaded.
```

These messages illustrate the intended output format.

### Long-Term Goals

The console architecture can be extended to support:

- Build output
- Runtime diagnostics
- Plugin messages
- Project analysis
- Validation warnings
- Background task activity

---

## 10. Technology Stack

JeridiEngine is primarily a native desktop application.

### Core Technologies

| Technology | Purpose |
|---|---|
| C++ | Native application logic and backend services |
| Qt 6 | Cross-platform application framework |
| Qt Quick | Declarative UI framework |
| QML | Desktop interface and reusable visual components |
| CMake | Project configuration and build system |
| Git | Source control and development history |

### Supported Project Ecosystems

JeridiEngine is being developed with modern web application projects in mind.

Its component and project models are intended to accommodate technologies such as:

**Frontend**
- React
- Next.js
- TypeScript
- JavaScript
- Vite
- Tailwind CSS
- Component libraries

**Backend**
- Node.js
- Express
- GraphQL
- Apollo Server
- REST APIs
- Backend services

These technologies describe target project ecosystems, not frameworks required to build the JeridiEngine desktop application.

Support levels may differ between project types.

---
<img width="1486" height="921" alt="image" src="https://github.com/user-attachments/assets/c253d235-d7e2-478c-99ac-e72f07b7ee4f" />

## 11. Architecture and Extensibility

One of the most important engineering goals is to prevent the application from becoming a collection of tightly coupled QML files and large controllers.

The architecture should allow the system to grow without making every new feature dependent on existing UI implementations.

### Conceptual Architecture

```text
JeridiEngine
│
├── Application Shell
│   ├── Startup
│   ├── Main Window
│   ├── Navigation
│   └── Workspace Management
│
├── Workspace System
│   ├── Panel Management
│   ├── Layout Management
│   ├── Panel Visibility
│   └── Workspace State
│
├── Development Tools
│   ├── Component Library
│   ├── Project Explorer
│   ├── Inspector
│   ├── Source Editor
│   ├── Live Preview
│   └── Output Console
│
├── Core Services
│   ├── Project Management
│   ├── File Operations
│   ├── Component Metadata
│   ├── Package Management
│   └── Application State
│
└── Platform Integration
    ├── Qt Framework
    ├── File System
    ├── Operating System
    └── Build and Deployment
```

This diagram describes the architectural direction, not an exact mapping of every current source directory or class.

### Design Objectives

**Separation of Concerns**

Presentation, application logic, project operations, and component metadata should have clearly defined responsibilities.

**Reusable UI Components**

Common controls, panel headers, search fields, property editors, and status indicators should be reusable.

**Data-Driven Interfaces**

Component definitions and metadata should determine available properties and configuration options wherever practical.

**Scalable Registration**

New components should be registered through extensible mechanisms rather than added through long chains of hardcoded conditions.

**Independent Development**

Individual tools should be maintainable without requiring major changes to unrelated workspace modules.

---

## 12. Getting Started

### Prerequisites

For building the application from source, the development environment requires:

- Qt 6 with the modules used by the project
- A compatible C++ compiler
- CMake
- Qt Creator or another CMake-compatible development environment
- Git

The current development environment uses Qt 6.12 on macOS.

### Clone the Repository

```bash
git clone https://github.com/amadich/Engine.git
cd Engine
```

### Open in Qt Creator

1. Launch Qt Creator.
2. Select **Open Project**.
3. Open `CMakeLists.txt`.
4. Select a compatible Qt 6 kit.
5. Configure the project.
6. Build and run the application.

### Build with CMake

A typical Qt installation can be used with:

```bash
cmake -S . -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="/path/to/Qt/6.12.0/platform"

cmake --build build --config Release
```

Replace the Qt path with the correct installation path for your system.

The exact Qt modules and platform dependencies are determined by the project's CMake configuration.

---

## 13. Platform Support

JeridiEngine is built using cross-platform technologies.

| Platform | Status |
|---|---|
| macOS Apple Silicon | Development and Release builds |
| macOS Intel | Not yet verified |
| Windows x64 | Planned build and validation |
| Linux | Planned build and validation |

### macOS

The application can be built as a native `.app` bundle.

Distribution work includes:

- Application branding
- Native icon integration
- Release builds
- Qt dependency deployment
- DMG packaging
- Application signing and notarization

### Windows

The Windows distribution goal includes:

- Native executable
- Windows application icon
- Required Qt DLLs and plugins
- Portable ZIP distribution
- Optional installer

### Linux

Future Linux distribution may include portable or distribution-specific packages.

Cross-platform compatibility remains subject to testing.

---

## 14. Development Roadmap

The roadmap represents development goals and is subject to change.

### Phase 1 — Application Foundation

- [x] Native Qt application foundation
- [x] Main workspace interface
- [x] Panel-based layout
- [x] Initial project navigation
- [x] Component Library interface
- [x] Inspector interface
- [x] Output Console interface

### Phase 2 — Developer Experience

- [x] Source editor interface
- [x] File reference and outline views
- [x] Searchable project resources
- [x] Component categorization
- [x] Package information views
- [ ] Expand source intelligence
- [ ] Improve keyboard-driven navigation

### Phase 3 — Component Intelligence

- [ ] Expand schema-driven property editing
- [ ] Support more component property types
- [ ] Improve dependency awareness
- [ ] Add component validation
- [ ] Introduce richer component previews
- [ ] Expand frontend and backend component catalogs

### Phase 4 — Workspace Extensibility

- [ ] Formalize extension interfaces
- [ ] Introduce a plugin registration system
- [ ] Support custom Inspector providers
- [ ] Support additional project adapters
- [ ] Improve workspace persistence
- [ ] Expand configurable layouts

### Phase 5 — Distribution

- [x] Application branding
- [x] macOS Release build
- [ ] Validate standalone macOS deployment
- [ ] Finalize macOS distribution package
- [ ] Build and test Windows x64 release
- [ ] Establish automated release pipelines
- [ ] Publish reproducible release artifacts

---

## 15. Project Status

JeridiEngine is an evolving software engineering project.

The current application demonstrates the foundations of a modular desktop development workspace, including project exploration, component management interfaces, inspection tools, source navigation, and output monitoring.

Some capabilities are implemented as functional interfaces, while others remain under active development or are part of the long-term architectural vision.

The project is not yet presented as a production-ready replacement for established IDEs.

Its development prioritizes architectural clarity, maintainability, and incremental improvements.

---

## 16. Contributing

Contributions, suggestions, and technical discussions are welcome.

Areas of particular interest include:

- Qt Quick and QML architecture
- C++ application design
- Reusable component systems
- Developer tooling
- Source analysis
- Workspace and docking systems
- Cross-platform deployment
- UI/UX improvements
- Performance and maintainability

For proposed changes, please open an issue describing the problem or enhancement before starting significant architectural work.

Pull requests should aim to preserve modularity and avoid unnecessary coupling between application subsystems.

---

## 17. License

Licensing information should be taken from the repository's `LICENSE` file.

A public repository does not automatically grant permission to redistribute or modify its source code.

---

## 18. Project Vision

JeridiEngine began with the idea of creating a development environment that could grow beyond a collection of fixed tools.

Its direction is toward a workspace where developers can explore software projects, inspect reusable components, understand project structure, and manage development resources through a consistent interface.

The goal is not simply to build another code editor.

It is to explore how **visual development tools, modular architecture, and traditional source-based workflows** can work together.

The project will continue to evolve through experimentation, practical development, and architectural refinement.

---

**JeridiEngine — Build with structure. Develop with clarity.**

Created and maintained by [amadich](https://github.com/amadich).

**Repository:** https://github.com/amadich/Engine
