# Análisis del skill `us-refinement` — feedback para iterar

Referencia: https://github.com/hjagar/us-refinement/blob/main/SKILL.md

## Fortalezas identificadas

- El gate de clarificación (Step 2) es flexible y no bloqueante — no interroga al socio antes de arrancar, documenta lo no confirmado como "assumptions" en vez de inventar.
- El bloque `AI-DATA` (HTML comment con metadata estructurada: id, type, dependencies, scope, scenarios) le da a Claude Code metadata parseable sin que el humano tenga que leer YAML a mano.
- El default de write-back a GitHub es "comment, no destructivo" — no pisa el body original de la issue.
- Buena separación de nivel de abstracción: no incluye código de implementación en la user story, dejando el "cómo" para la spec técnica (`/sdd-new`).

## Puntos a revisar

### 1. Step 0.5 — Environment/Storage Setup (Engram/openspace/hybrid)
Preguntar entre 4 modos de storage en cada invocación agrega ceremonia.

**Resolución:** no aplica para este caso — es una decisión pensada para mí y para otras personas que puedan usar el skill y entiendan el tema, no para los socios del cliente. Se mantiene como está.

### 2. Step 1.5 — Technical feasibility scan
Escanear PATH y repo en cada refinamiento suma latencia y puede generar preguntas de clarificación innecesarias si hay múltiples matches de archivo.

**Resolución:** tomarlo como mejora a evaluar — considerar hacerlo opt-in (ej. `/refine --deep`) en vez de obligatorio en cada corrida.

### 3. AI-DATA — `id: US[number]` sin fuente de verdad clara
Si el ID no se deriva automáticamente del número de issue de GitHub, puede haber colisiones o numeración manual inconsistente entre los dos proyectos (Laravel/React).

**Resolución:** aceptado — atar el ID directamente al número de issue (`US-{issue_number}`) para que sea determinístico.

### 4. Assumptions enterradas en el body del comentario
Si un socio scrollea la lista de issues, no ve a simple vista cuáles tienen supuestos sin confirmar.

**Resolución:** aceptado — agregar una sección explícita y separada:

```markdown
## Assumptions
- [ ] Se asume que el endpoint de autenticación ya soporta refresh tokens (no confirmado)
- [ ] Se asume que "usuario activo" excluye soft-deleted (no confirmado)
```

Razones para que sea una sección propia y con checkboxes:
- Separada del Given/When/Then y de la narrativa, para que sea parseable como sección con semántica propia ("supuesto del agente", no "hecho confirmado por el humano").
- Los checkboxes permiten que un socio confirme un supuesto con un solo click desde la UI de GitHub, sin escribir nada — coherente con la postura de absorber el trabajo de escritura como contratista.
- Si al menos un ítem queda sin tickear, el skill puede aplicar automáticamente el label `needs-review-assumptions` en el Step 4 (Step 4 detecta: ¿hay checkboxes sin marcar en "## Assumptions"? → sí → aplicar label).
- Si la sección está vacía o todo tickeado, el issue queda listo para picar sin pasar por nadie más.

## Resumen de próximos pasos para el skill
- [ ] Mantener Step 0.5 sin cambios (uso personal/avanzado, no para el cliente)
- [ ] Evaluar hacer Step 1.5 opt-in
- [ ] Cambiar generación de `id` en AI-DATA a `US-{issue_number}`
- [ ] Agregar sección explícita "## Assumptions" con checkboxes
- [ ] Agregar lógica en Step 4 para aplicar label `needs-review-assumptions` según estado de los checkboxes
