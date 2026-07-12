# Skills en Cursor — análisis de `us-refinement`

Documento de opinión, instalación y mejoras desde la perspectiva de **Cursor como único agente** en una PC Windows.

---

## ¿Qué son los skills en Cursor?

Son carpetas con un `SKILL.md` que el agente carga cuando detecta que el pedido del usuario coincide con la `description` del frontmatter, o cuando el usuario invoca el skill de forma explícita (por ejemplo `/refine`, `/refinar`, o mencionando el nombre).

No son extensiones ni plugins binarios: son instrucciones en markdown que extienden el comportamiento del modelo sin tocar el IDE.

Cursor expone los skills disponibles en el contexto del sistema bajo `<available_skills>`. El modelo usa la `description` de cada skill para decidir si aplicarlo automáticamente.

### Estructura esperada

```text
skill-name/
├── SKILL.md              # obligatorio
├── scripts/              # opcional (utilidades)
├── docs/                 # opcional (referencia)
└── tests/                # opcional (fixtures de validación)
```

### Frontmatter YAML (obligatorio)

```yaml
---
name: us-refinement
description: Refines user stories. Trigger on /refine, /refinar, raw stories, GitHub issues, or agile terms.
---
```

Solo `name` y `description` son obligatorios. La `description` es el campo más importante: si es vaga, el skill no se dispara cuando debe; si es demasiado verbosa, aumenta falsos positivos.

### Campo opcional relevante: `disable-model-invocation`

Los skills del ecosistema SDD en Cursor suelen llevar `disable-model-invocation: true` porque solo deben ejecutarse bajo comando explícito (`/sdd-new`, `/sdd-spec`, etc.).

`us-refinement` **no** debería llevarlo: el valor por defecto en Cursor es auto-invocación, y este skill está diseñado para dispararse también al pegar una historia cruda o mencionar criterios de aceptación.

---

## Dónde instalarlo (solo Cursor en la PC)

### Ruta canónica (recomendada)

| Tipo | Ruta | Ámbito |
|------|------|--------|
| **Personal (global)** | `~/.cursor/skills/us-refinement/SKILL.md` | Todos los proyectos |
| **Proyecto** | `.cursor/skills/us-refinement/SKILL.md` | Solo ese repositorio |

En Windows, la ruta global equivale a:

```text
C:\Users\<usuario>\.cursor\skills\us-refinement\SKILL.md
```

### Ruta que NO debés usar

```text
~/.cursor/skills-cursor/
```

Ese directorio lo gestiona Cursor para skills internos del producto (`create-skill`, `canvas`, `babysit`, etc.). No es para skills de usuario.

### Veredicto para “solo Cursor”

**Instalá en `~/.cursor/skills/us-refinement/`** si refinás historias en varios repos.

**Instalá en `.cursor/skills/us-refinement/`** solo si el skill es exclusivo de un proyecto y querés versionarlo con el equipo vía git.

Para desarrollar este repo (`us-refinement`), lo más práctico es **junction global** al checkout local: los cambios en `SKILL.md` se reflejan al instante sin reinstalar.

```powershell
# Desde PowerShell, en el repo us-refinement
$skillsDir = Join-Path $env:USERPROFILE ".cursor\skills"
$target    = Join-Path $skillsDir "us-refinement"
$source    = (Get-Location).Path

New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null
if (Test-Path $target) { Remove-Item $target -Recurse -Force }
cmd /c mklink /J `"$target`" `"$source`"
```

Si preferís copia en lugar de junction (sin live-reload):

```powershell
$target = Join-Path $env:USERPROFILE ".cursor\skills\us-refinement"
New-Item -ItemType Directory -Path $target -Force | Out-Null
Copy-Item -Path ".\SKILL.md" -Destination $target -Force
Copy-Item -Path ".\scripts" -Destination $target -Recurse -Force
Copy-Item -Path ".\tests"  -Destination $target -Recurse -Force
```

### Gap actual del instalador

`install.ps1` / `install.sh` **no incluyen** `~/.cursor/skills/us-refinement` en `AgentPaths`. Hoy instalan en Claude, Gemini, OpenCode, Copilot y `.agents`, pero no en Cursor.

Mejora concreta para el repo: agregar esta línea en ambos instaladores:

```powershell
$AgentPaths.Add((Join-Path $HomeDir ".cursor\skills\us-refinement"))
```

```bash
AGENT_PATHS+=("$HOME/.cursor/skills/us-refinement")
```

Y, en modo `-Local`, preferir **junction/symlink** de la carpeta completa (no solo copiar `SKILL.md`), para que `scripts/validate_refinement.py` y `tests/` sigan disponibles durante el desarrollo.

### Nota sobre `~/.claude/skills/`

Si el skill ya está en `~/.claude/skills/us-refinement/`, puede aparecer en sesiones de Cursor en entornos multi-agente, pero **no es la ruta documentada por Cursor**. Para un setup “solo Cursor”, migrá a `~/.cursor/skills/` y evitá depender de rutas de otros agentes.

---

## Cómo verificar que Cursor lo reconoce

1. Reiniciá el chat del agente (o abrí una ventana nueva) después de instalar.
2. En un chat nuevo, pegá una historia cruda:

   ```text
   Como administrador quiero poder exportar reportes en PDF para compartirlos con el equipo.
   ```

3. El agente debería aplicar el flujo de refinamiento (INVEST → preguntas opcionales → output Given/When/Then) sin que tengas que escribir `/refine`.
4. También podés forzar con `/refine` o `/refinar`, o con `/refine --deep` para el escaneo técnico opt-in.

Si no se dispara, revisá:

- Que el directorio se llame exactamente `us-refinement` (igual que `name` en el frontmatter).
- Que exista `SKILL.md` dentro, no un `.md` suelto en otra ruta.
- Que la `description` del frontmatter mencione los triggers clave.

---

## Opinión sobre `SKILL.md`

### Puntos fuertes

**Gate flexible (Step 2).** La mejor decisión del diseño. No bloquea hasta tener todas las respuestas; ofrece avanzar con supuestos explícitos como checkboxes sin marcar. Respeta el tiempo del usuario y produce un artefacto útil de todas formas.

**Integración GitHub bien acotada (Steps 0B y 4).** Usa `gh` pero no adivina si falla. El write-back es opt-in (comentario vs reemplazar body). El label `needs-review-assumptions` es un detalle maduro que conecta refinamiento con el flujo de review en GitHub.

**Output accionable.** Given/When/Then con unhappy paths, dependencias, assumptions condicionales y bloque `[AI-DATA]` oculto para herramientas downstream. No es un resumen de reunión: es material listo para diseño técnico o SDD.

**Modo `--deep` opt-in (Step 1.5).** El escaneo de PATH y componentes del repo no penaliza el flujo estándar. El tip en Standard Mode que sugiere `--deep` es un buen nudge sin ejecutar comandos de más.

**Separación de concerns.** Las style notes prohíben código de implementación en la historia refinada y dejan el “cómo” para `/sdd-new`. Correcto.

**Instrucciones en inglés, respuesta en idioma del usuario.** Patrón token-eficiente que funciona bien en Cursor con usuarios hispanohablantes.

### Críticas (desde Cursor)

**1. Validación de “Small” enterrada en style notes.**

La regla “flag it BEFORE refining, not after” está al final del archivo, no en el flujo principal. Si el modelo llega al Step 2 con una historia que debería dividirse, ya perdió el momento.

**2. “Technical scope” en el output.**

La sección `Backend: yes/no / Frontend: yes/no` pertenece más al diseño técnico que al refinamiento. Un PO no siempre sabe la partición; además el bloque `[AI-DATA]` ya captura `scope.backend` / `scope.frontend` para máquinas. La sección humana duplica fricción.

**3. Description del frontmatter demasiado larga.**

Lista muchos triggers con ejemplos. En Cursor eso compite por tokens en `<available_skills>` y puede aumentar falsos positivos. El detalle ya está en “When to activate” del cuerpo.

**4. Step 0.5 (storage / Engram) es pesado para muchos usuarios de Cursor.**

Preguntar modo `engram | openspec | hybrid | hybrid-delayed` al inicio de cada refinamiento agrega fricción si el usuario no tiene Engram ni SDD. En Cursor conviene default silencioso: consola + clipboard, y solo preguntar storage si detectás `openspec/` o el MCP `engram` activo.

**5. El instalador no copia el payload completo.**

Solo copia `SKILL.md`. El validador (`scripts/validate_refinement.py`) y los mocks de test quedan fuera. Para Cursor, conviene instalar la carpeta completa o documentar que la validación se corre desde el repo.

**6. Sin `references/` para progressive disclosure.**

El `SKILL.md` tiene ~200 líneas (bien bajo el límite de 500), pero Step 4 (GitHub write-back + labels) y las reglas del bloque `[AI-DATA]` podrían vivir en `references/github-writeback.md` y `references/ai-data-schema.md` para mantener el archivo principal más escaneable.

---

## Mejoras recomendadas (priorizadas)

### Alta prioridad

| # | Mejora | Por qué en Cursor |
|---|--------|-------------------|
| 1 | Agregar `~/.cursor/skills/us-refinement` a `install.ps1` / `install.sh` | Hoy el instalador ignora Cursor por completo |
| 2 | Nuevo **Step 1.2: Scope pre-check** entre Step 1 y Step 2 | Evita refinar historias que deberían partirse |
| 3 | Acortar `description` del frontmatter | Mejor descubrimiento y menos falsos positivos |
| 4 | Step 0.5 con default silencioso | Menos fricción en sesiones sin Engram/SDD |

Ejemplo de Step 1.2:

```markdown
## Step 1.2: Scope pre-check (Small)

If Step 1 flags a "Small" violation or unrelated features bundled together,
STOP before Step 2. Tell the user and offer to split the story.
Continue only if the user confirms the current scope.
```

Ejemplo de description más ajustada:

```yaml
description: Refines raw user stories into INVEST-checked specs with Given/When/Then criteria. Use on /refine, /refinar, pasted stories, GitHub issue refinement, or when acceptance criteria are missing.
```

### Media prioridad

| # | Mejora | Detalle |
|---|--------|---------|
| 5 | Sacar `### Technical scope` del markdown visible | Mantener scope solo en `[AI-DATA]` si hace falta para downstream |
| 6 | Post-refinamiento: sugerir `python scripts/validate_refinement.py` | Feedback loop al estilo del skill `create-skill` de Cursor |
| 7 | Modo `-Local` con junction de carpeta completa | Live-reload al editar el skill en este repo |
| 8 | `references/` para GitHub write-back y schema AI-DATA | Progressive disclosure |

### Baja prioridad

| # | Mejora | Detalle |
|---|--------|---------|
| 9 | Slash command alias documentado | Cursor no tiene registro formal de slash commands; `/refine` funciona por coincidencia de texto en la conversación |
| 10 | Skill de proyecto en `.cursor/skills/` | Útil si querés que el equipo del repo `us-refinement` tenga el skill versionado sin instalación global |

---

## Comparación rápida con otros agentes

| Aspecto | Cursor | Claude Code | OpenCode |
|---------|--------|-------------|----------|
| Ruta global | `~/.cursor/skills/<name>/` | `~/.claude/skills/<name>/` | `~/.config/opencode/skills/<name>/` |
| Ruta proyecto | `.cursor/skills/<name>/` | `.claude/skills/<name>/` | `.opencode/skills/<name>/` |
| Auto-trigger | Por `description` (default) | Por `description` | Por `description` |
| Comando explícito | Texto en chat (`/refine`) | `Skill({ skill: "..." })` | `skill({ name: "..." })` |
| Instalador de este repo | **No incluido aún** | Sí | Sí |

---

## Resumen ejecutivo

| Pregunta | Respuesta |
|----------|-----------|
| ¿Dónde instalar si solo uso Cursor? | `C:\Users\<usuario>\.cursor\skills\us-refinement\` (global) o `.cursor/skills/us-refinement/` (proyecto) |
| ¿Dónde NO instalar? | `~/.cursor/skills-cursor/` (reservado a Cursor) |
| ¿Cómo desarrollar este repo con live-reload? | Junction desde `~/.cursor/skills/us-refinement` al checkout |
| ¿Qué le falta al instalador? | Entrada para `~/.cursor/skills/` y, idealmente, carpeta completa en modo local |
| ¿Calidad del skill? | Muy alta; las mejoras son de flujo (scope pre-check), descubrimiento (description) y adaptación al ecosistema Cursor (installer + Step 0.5 más liviano) |

El skill está listo para producción en Cursor. El cambio más impactante para tu caso (“solo Cursor en la PC”) es **instalarlo en `~/.cursor/skills/us-refinement/`** y **extender el instalador** para que ese paso sea automático en futuras versiones.
