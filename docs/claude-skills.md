# Skills en Claude Code

## ¿Qué son?

Son instrucciones reutilizables que Claude carga bajo demanda mediante la herramienta interna `Skill`. Cada skill define su comportamiento en un `SKILL.md` con frontmatter YAML. Cuando el usuario escribe un comando tipo `/us-refinement` o el modelo detecta que el request coincide con la descripción del skill, lo invoca y ejecuta las instrucciones del archivo.

No son plugins de código — son instrucciones en lenguaje natural que extienden el comportamiento del modelo sin tocar el binario de Claude Code.

## Estructura

Cada skill vive en su propia carpeta con un `SKILL.md` adentro.

| Ubicación | Ámbito |
|---|---|
| `.claude/skills/<nombre>/SKILL.md` | Proyecto |
| `~/.claude/skills/<nombre>/SKILL.md` | Global |

Claude Code escanea ambas ubicaciones al arrancar y expone los skills disponibles en el contexto del sistema bajo `<available_skills>`.

## Frontmatter YAML (obligatorio)

```yaml
---
name: us-refinement
description: Refines raw user stories before they move to technical design. Trigger when the user pastes a story, references a GitHub issue for refinement, or asks about acceptance criteria.
---
```

Solo `name` y `description` son requeridos. La `description` es lo más importante: el modelo la usa para decidir cuándo invocar el skill automáticamente. Si es vaga, el skill se va a disparar cuando no debe (o no se va a disparar cuando sí debe).

## Cómo se invoca

**Explícito** — el usuario escribe el nombre del skill como slash command:
```
/us-refinement
```

**Implícito** — el modelo detecta que el request coincide con la `description` del frontmatter y llama al skill sin que el usuario lo sepa. Por eso la descripción tiene que ser precisa.

Internamente, Claude ejecuta:
```
Skill({ skill: "us-refinement", args: "..." })
```

## Reglas de naming

- Minúsculas y guiones únicamente: `[a-z0-9]+(-[a-z0-9]+)*`
- El nombre del directorio debe coincidir con el campo `name` del frontmatter
- Descriptivo y breve: `go-testing`, `branch-pr`, `us-refinement`

## Contenido del SKILL.md

No hay formato fijo para el cuerpo. Es instrucción en prosa para el modelo. Lo que sí importa:

- **Cuándo activarse**: condiciones explícitas, no vagas.
- **Qué pasos seguir**: paso a paso, en orden. El modelo los ejecuta secuencialmente.
- **Qué NO hacer**: los límites son tan importantes como las instrucciones. Si el skill no debe invocar otro comando, decilo explícitamente.
- **Formato de salida**: si el output tiene estructura (markdown, JSON, tabla), especificala. El modelo improvisa si no le decís.
- **Idioma**: si el skill está en inglés (por eficiencia de tokens), aclararlo al principio y recordarle al modelo que responda en el idioma del usuario.

---

# Review del skill `us-refinement`

Archivo: `~/.claude/skills/us-refinement/SKILL.md`

## Puntos fuertes

**Flexible gate (Step 2).**
La mejor decisión del archivo. En vez de bloquear hasta tener todas las respuestas, ofrece avanzar con supuestos explícitos documentados. Eso respeta el tiempo del usuario y produce output igualmente útil. La mayoría de los skills no llegan a este nivel de diseño.

**GitHub integration bien implementada (Steps 0B y 4).**
Maneja el error de `gh` correctamente — no adivina, informa y pide que se pegue el texto manual. Y antes de escribir de vuelta a GitHub, pregunta. No asume.

**Output accionable.**
El formato Given/When/Then con unhappy paths obligatorios, la sección de dependencias, y las asunciones separadas hacen que el output sea consumible directamente por el equipo técnico. No es un resumen de reunión, es un artefacto de trabajo.

**Style notes con criterio.**
"No inventar preguntas si la historia ya está clara" y "no corporate filler" son guardrails reales. Sin eso, el modelo tiende a hacer el sketch completo aunque el input ya sea bueno.

## Críticas

### 1. El check de "Small" está en el lugar equivocado

El skill dice en las style notes: "flag it BEFORE refining, not after". Pero esa instrucción está enterrada al final del archivo, no en el flujo principal. Si el modelo llega al Step 2 con una historia que debería dividirse, ya perdió el momento.

La validación de "Small" (y de "mezcla features no relacionados") tiene que ser un paso explícito entre Step 1 y Step 2 — no una nota de estilo. Algo así:

```
## Step 1.5: Pre-check de scope

Si el análisis INVEST detecta violación de "Small" o mezcla de features no relacionados,
DETENER y notificar al usuario ANTES de hacer cualquier pregunta de refinamiento.
Ofrecer partir la historia en dos. Solo continuar si el usuario confirma el scope actual.
```

### 2. "Technical scope" es territorio del SDD

La sección de output que pide declarar "Backend: yes/no — which parts / Frontend: yes/no — which parts" pertenece al diseño técnico, no al refinamiento. Una historia refinada no debería pre-decidir la arquitectura — eso es exactamente el trabajo de `/sdd-new`.

Incluirlo acá introduce fricción innecesaria en el Step 2 (¿el PO sabe si es backend o frontend?) y genera un output que parece más diseño técnico que historia de usuario. Sacar esa sección y dejar que el SDD la resuelva es más limpio.

### 3. Description del frontmatter demasiado verbosa

La descripción actual lista todos los trigger cases posibles con ejemplos concretos. El problema: el modelo usa ese campo para decidir cuándo invocar el skill automáticamente, y tanto detalle aumenta el riesgo de falsos positivos.

Una descripción más ajustada y directa funciona mejor:

```yaml
description: Refines raw user stories before technical design. Trigger when the user pastes a story, references a GitHub issue for refinement, or a story lacks acceptance criteria.
```

El "cuándo activarse" en detalle ya está en el cuerpo del skill, en "When to activate". El frontmatter no necesita duplicarlo.
