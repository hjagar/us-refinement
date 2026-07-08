# us-refinement

[English](#english) | [Español](#español)

---

## English

`us-refinement` is a portable AI assistant tailored to interactively refine user stories into structured specifications before moving to technical design or implementation.

### Key Features

1. **INVEST-driven Refinement**: Assesses raw user stories (or issues) against INVEST principles (Independent, Negotiable, Valuable, Estimable, Small, Testable).
2. **Behavioral Acceptance Criteria**: Generates explicit **Given/When/Then** scenarios covering happy paths and edge cases.
3. **Invisible AI Zone**: Formats human-facing specifications in the local language (e.g., Spanish) while injecting a hidden HTML comment block (`<!-- ... -->`) in English at the end. This keeps the project board clean for humans while giving token-efficient, unambiguous prompts to AI tools reading the issues via APIs.
4. **Multi-Agent Portability**: Optimized to be easily ported and run across multiple AI agents (Gentle AI / Antigravity CLI, Claude Code, Cursor, Windsurf, Copilot, etc.).
5. **Environment Auto-Detection**: Dynamically checks for tools like `engram`, `gh` cli, or SDD systems to adjust its storage and execution strategies.

### Quick Start

Choose one of the following installation methods:

#### A. Remote Installation (Recommended)
Run the remote script directly from GitHub without cloning the repository. This will download the latest stable release ZIP and link it to all detected agents.

* **Windows (PowerShell)**:
  ```powershell
  irm https://raw.githubusercontent.com/hjagar/us-refinement/main/install.ps1 | iex
  ```
* **macOS / Linux (Bash)**:
  ```bash
  curl -sSL https://raw.githubusercontent.com/hjagar/us-refinement/main/install.sh | bash
  ```

#### B. Manual Local Installation (Development)
If you want to contribute or run in local/development mode:
1. Clone this repository:
   ```bash
   git clone https://github.com/hjagar/us-refinement.git
   cd us-refinement
   ```
2. Run the installer script locally:
   * **Windows (PowerShell)**:
     ```powershell
     .\install.ps1 -Local
     ```
   * **macOS / Linux (Bash)**:
     ```bash
     ./install.sh --local
     ```

2. Configure it globally for your specific AI agent:
   - **Antigravity / Gentle AI**: Add the repository path to your global `skills.json`.
   - **Claude Code**: Reference the guidelines in your global `CLAUDE.md`.
   - **Cursor / OpenCode**: Append the rules to your `.cursorrules` file.

#### C. Updating
To update the skill to the latest version available on GitHub:
* **Windows (PowerShell)**:
  ```powershell
  & "$HOME\.hjagar\skills\us-refinement\update.ps1"
  ```
* **macOS / Linux (Bash)**:
  ```bash
  "$HOME/.hjagar/skills/us-refinement/update.sh"
  ```

### Acknowledgements

Special thanks to [Alan Buscaglia](https://github.com/Gentleman-Programming) ([@Gentleman-Programming](https://github.com/Gentleman-Programming)), creator of [Engram](https://github.com/Gentleman-Programming/engram), for providing the persistent memory backend that makes hybrid and hybrid-delayed storage possible.

---

## Español

`us-refinement` es un asistente portátil diseñado para refinar historias de usuario de forma interactiva y estructurada antes de pasar al diseño técnico o al desarrollo. 

### Características principales

1. **Refinamiento basado en INVEST**: Evalúa la historia cruda (o issue) bajo los criterios INVEST (Independiente, Negociable, Valiosa, Estimable, Pequeña, Testable).
2. **Criterios de Aceptación Claros**: Genera escenarios en formato **Given/When/Then** cubriendo caminos felices y casos de borde.
3. **Zona Oculta para IA (Invisible AI Zone)**: Escribe la especificación para humanos en el idioma local (ej. Español) e inyecta al final un bloque oculto de comentarios HTML (`<!-- ... -->`) en inglés con los criterios traducidos y metadatos optimizados. Esto mantiene la interfaz visual limpia para el equipo y le da instrucciones precisas y token-eficientes a cualquier IA que lea el issue mediante API.
4. **Portabilidad Multi-Agente**: Diseñado para funcionar en múltiples herramientas (Gentle AI / Antigravity CLI, Claude Code, Cursor, Windsurf, Copilot, etc.).
5. **Autodetección de Entorno**: Reconoce dinámicamente si herramientas como `engram`, `gh` cli o flujos SDD están disponibles para adaptar su flujo.

### Instalación rápida

Elegí uno de los siguientes métodos de instalación:

#### A. Instalación remota (Recomendado)
Ejecutá el instalador directamente desde GitHub sin necesidad de clonar el repositorio. Esto descargará la última versión estable (ZIP) y la enlazará con todos los agentes detectados.

* **Windows (PowerShell)**:
  ```powershell
  irm https://raw.githubusercontent.com/hjagar/us-refinement/main/install.ps1 | iex
  ```
* **macOS / Linux (Bash)**:
  ```bash
  curl -sSL https://raw.githubusercontent.com/hjagar/us-refinement/main/install.sh | bash
  ```

#### B. Instalación local manual (Desarrollo)
Si querés colaborar con el proyecto o correr en modo local/desarrollo:
1. Cloná este repositorio:
   ```bash
   git clone https://github.com/hjagar/us-refinement.git
   cd us-refinement
   ```
2. Ejecutá el instalador de forma local:
   * **Windows (PowerShell)**:
     ```powershell
     .\install.ps1 -Local
     ```
   * **macOS / Linux (Bash)**:
     ```bash
     ./install.sh --local
     ```

2. Agrégalo a tus configuraciones globales según tu agente de IA:
   - **Antigravity / Gentle AI**: Añade la ruta del repositorio a tu `skills.json` global.
   - **Claude Code**: Referencia las instrucciones en tu `CLAUDE.md`.
   - **Cursor / OpenCode**: Copia las directivas en tu archivo `.cursorrules`.

#### C. Actualización
Para actualizar el skill a la última versión disponible en GitHub:
* **Windows (PowerShell)**:
  ```powershell
  & "$HOME\.hjagar\skills\us-refinement\update.ps1"
  ```
* **macOS / Linux (Bash)**:
  ```bash
  "$HOME/.hjagar/skills/us-refinement/update.sh"
  ```

### Agradecimientos

Un agradecimiento especial a [Alan Buscaglia](https://github.com/Gentleman-Programming) ([@Gentleman-Programming](https://github.com/Gentleman-Programming)), creador de [Engram](https://github.com/Gentleman-Programming/engram), por proveer el motor de memoria persistente que hace posible el almacenamiento híbrido y diferido (`hybrid-delayed`).
