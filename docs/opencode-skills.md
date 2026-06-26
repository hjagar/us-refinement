# Skills en OpenCode

## ¿Qué son?

Son instrucciones reutilizables en archivos `SKILL.md` que el agente carga bajo demanda mediante la herramienta `skill`. Actúan como plugins de comportamiento: describís qué hace el skill y cuándo usarlo, y OpenCode se lo inyecta al LLM cuando corresponde.

## Estructura

Cada skill es una carpeta con un `SKILL.md` adentro. Ubicaciones que OpenCode escanea:

| Ubicación | Ámbito |
|---|---|
| `.opencode/skills/<nombre>/SKILL.md` | Proyecto |
| `~/.config/opencode/skills/<nombre>/SKILL.md` | Global |
| `.claude/skills/<nombre>/SKILL.md` | Proyecto (compatible Claude) |
| `~/.claude/skills/<nombre>/SKILL.md` | Global (compatible Claude) |
| `.agents/skills/<nombre>/SKILL.md` | Proyecto (compatible Agents) |
| `~/.agents/skills/<nombre>/SKILL.md` | Global (compatible Agents) |

## Frontmatter YAML (obligatorio)

```yaml
---
name: git-release
description: Create consistent releases and changelogs
license: MIT            # opcional
compatibility: opencode # opcional
metadata:               # opcional, map string->string
  audience: maintainers
---
```

Solo `name` y `description` son requeridos.

## Reglas de naming

- 1–64 caracteres
- Minúsculas + guiones (`[a-z0-9]+(-[a-z0-9]+)*`)
- Sin guiones dobles (`--`) ni al inicio/final
- El nombre del directorio debe coincidir con `name` en frontmatter

## Descubrimiento

OpenCode camina hacia arriba desde el CWD hasta el git worktree y recolecta todo `skills/*/SKILL.md` que encuentra. También carga los globales. Los skills disponibles se exponen en el `skill` tool del agente:

```xml
<available_skills>
  <skill>
    <name>git-release</name>
    <description>Create consistent releases and changelogs</description>
  </skill>
</available_skills>
```

El agente carga un skill llamando:

```
skill({ name: "git-release" })
```

## Permisos (`opencode.json`)

```json
{
  "permission": {
    "skill": {
      "*": "allow",
      "pr-review": "allow",
      "internal-*": "deny",
      "experimental-*": "ask"
    }
  }
}
```

| Valor | Comportamiento |
|---|---|
| `allow` | Carga inmediata |
| `deny` | Oculto del agente, acceso rechazado |
| `ask` | Pregunta al usuario antes de cargar |

Se pueden override por agente (en frontmatter del agente custom o en `opencode.json` para built-in).

También se puede deshabilitar completamente el skill tool:

```yaml
# en frontmatter de agente custom
---
tools:
  skill: false
---
```

```json
// en opencode.json para built-in
{
  "agent": {
    "plan": {
      "tools": {
        "skill": false
      }
    }
  }
}
```

---

# Review del skill `us-refinement`

Archivo: `~/.claude/skills/us-refinement/SKILL.md`

## Puntos fuertes

- **Estructura clara**: pasos bien definidos (0–5), fácil de seguir.
- **Flexible gate** (Step 2): pregunta lo que falta pero deja que el user decida "dále nomás con lo que hay" sin bloquear. Las assumptions quedan documentadas explícitamente.
- **Output con metadata estructurada**: el bloque `<!-- AI: ... -->` al final del formato es machine-parseable para pipelines downstream.
- **GitHub integration** (Step 0B + Step 4): bien implementada, con safety checks (no fabricar datos, preguntar antes de escribir).
- **Split-check before refining**: detecta si la historia viola *Small* y lo avisa antes de refinar, no después.
- **Style notes prácticas**: "no inventar preguntas si el story ya está claro", "no corporate filler".

## Críticas

### 1. El análisis INVEST queda oculto (Step 1)

El skill dice "silently note gaps" y no muestra el resultado del análisis INVEST al usuario. **Error de teaching.** Mostrar por qué se pregunta lo que se pregunta — "Esto viola *Small* porque mezcla dos features" — educa al user para que escriba mejores stories la próxima vez. Un resumen breve post-análisis suma visibilidad sin costo.

### 2. Description del frontmatter demasiado verbosa

La descripción intenta enumerar todos los trigger cases posibles en vez de delegar en la sección "When to activate". Algo como `Refines raw user stories before technical design` alcanza. La regla es 1024 chars, pero eso no obliga a usarlos todos.

### 3. Tono general

Bien logrado: directo, sin vueltas, sin jargon corporativo. Se nota que prioriza claridad sobre protocolo.
