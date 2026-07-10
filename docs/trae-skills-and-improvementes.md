# Análisis del Skill `us-refinement` para TRAE

## 1. Opinión sobre [SKILL.md](../SKILL.md)

¡Excelente trabajo! El `SKILL.md` es muy bien estructurado y tiene muchas fortalezas:

- **Análisis INVEST silencioso primero** (Step 1): Evalúa la historia sin saturar al usuario con teoría ágil, usando esos criterios internamente para generar preguntas dirigidas.
- **Gate flexible en Step 2**: No bloquea el avance si falta información; ofrece refinar con lo que hay y marcar lo no confirmado como "assumptions" — esa es la mejor decisión del diseño.
- **Integración GitHub con manejo de errores** (Steps 0B y 4): Usa `gh CLI` pero falla con gracia si no está autenticado, no adivina contenido. Y antes de escribir de vuelta a GitHub, pide una elección explícita (comentario o reemplazo del body).
- **Formato de salida accionable**: Scenarios Given/When/Then (incluyendo unhappy paths), sección de dependencias y assumptions.
- **Separación de concerns** (style notes): No incluye código ni diseño técnico en la historia de usuario — eso es trabajo del `/sdd-new`.


## 2. Mejoras sugeridas

Aquí hay algunas oportunidades de mejora, basadas en los análisis del repositorio:

### A. Step 1.5 ya es opt‑in con `--deep` (¡genial!)
Ya tienes este cambio implementado: el escaneo técnico (`Step 1.5`) solo se ejecuta si el usuario pasa el flag `--deep`. Perfecto, evita latencia innecesaria en el modo normal.

### B. Validación de "Small" (dividir historia) debe ser un paso explícito
En las [style notes](../SKILL.md#L197-L203) tienes la regla: "flag it BEFORE refining, not after". Pero está enterrada al final. Deberías convertirla en un paso explícito entre Step 1 y Step 2:

```
## Step 1.2: Pre‑check de scope (Small)
Si el análisis INVEST detecta que la historia viola el criterio "Small" o mezcla features no relacionados, DETENER y notificar al usuario ANTES de hacer cualquier pregunta de refinamiento. Ofrecer partir la historia en dos. Solo continuar si el usuario confirma el scope actual.
```

### C. Reconsiderar la sección "Technical scope" en el output
Como dice [docs/claude-skills.md](./claude-skills.md#L97-L101), la sección de "Technical scope" (backend sí/no, frontend sí/no) pertenece más al diseño técnico (`/sdd-new`), no al refinamiento de la historia. Un PO no necesariamente sabe si algo es backend o frontend. Podrías sacarla del output y dejar que el SDD la resuelva.

### D. Descripción del frontmatter más concisa
La descripción actual del frontmatter es muy verbosa (lista todos los triggers con ejemplos). Podrías acortarla para reducir falsos positivos:

```yaml
description: Refines raw user stories before technical design. Trigger when the user pastes a story, references a GitHub issue for refinement, or asks about acceptance criteria.
```

(ya tienes la lista detallada de triggers en la sección "When to activate" del cuerpo, no hace falta duplicarla en el frontmatter).


## 3. Instalación del Skill para que TRAE lo reconozca

¡Este repositorio ya tiene instaladores listos para usar! ([install.ps1](../install.ps1) para Windows y [install.sh](../install.sh) para macOS/Linux).

### Opciones de instalación:

#### Opción A: Instalación local (para desarrollo, edita el skill y los cambios se ven en vivo)
Si estás desarrollando el skill y quieres que los cambios en este directorio se vean inmediatamente en los agentes:
```powershell
.\install.ps1 -Local
```

#### Opción B: Instalación global (descarga la última versión y la instala para todos los agentes)
```powershell
# Ejecuta esto en PowerShell (no hace falta estar en el directorio del repo)
irm https://raw.githubusercontent.com/hjagar/us-refinement/main/install.ps1 | iex
```

### ¿Qué hace el instalador?
El instalador configura el skill para las herramientas de IA más comunes, creando enlaces/symlinks en:
- **Antigravity/Gentle AI**: `C:\Users\<tu-usuario>\.gemini\config\skills\us-refinement`
- **Claude Code**: `C:\Users\<tu-usuario>\.claude\skills\us-refinement`
- **OpenCode/Cursor**: `C:\Users\<tu-usuario>\.config\opencode\skills\us-refinement`
