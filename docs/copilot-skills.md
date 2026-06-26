# GitHub Copilot CLI Skills

## ¿Qué son los Skills?

Los **skills** son capacidades especializadas que extienden las funciones de GitHub Copilot CLI. Te permiten automatizar patrones de trabajo comunes en tu proyecto, mejorando la productividad y consistencia en tareas recurrentes.

### Características principales

- **Reutilizables**: Define una vez, usa múltiples veces
- **Contextuales**: Se activan automáticamente según triggers configurados
- **LLM-first**: Están diseñados para ser interpretados por modelos de lenguaje
- **Bilingües**: Las instrucciones pueden estar en inglés (eficientes), pero responden en el idioma del usuario

---

## Cómo usar Skills

### Comando principal

```bash
/skills
```

Este comando te permite **ver, gestionar y seleccionar skills** disponibles en tu proyecto.

### Skills disponibles en este proyecto

- **branch-pr** - Crear pull requests amables con validaciones de issues
- **chained-pr** - Dividir PRs grandes en PRs encadenadas para mejor revisión
- **cognitive-doc-design** - Diseñar documentación que reduce carga cognitiva
- **comment-writer** - Escribir comentarios colaborativos cálidos y directos
- **go-testing** - Aplicar patrones de testing enfocados en Go
- **judgment-day** - Ejecutar revisión dual (blind review)
- **work-unit-commits** - Planificar commits como unidades revisables
- **us-refinement** - Refinar user stories antes de pasar a especificación técnica

---

## Cómo crear un Skill

### Estructura básica

Un skill es un archivo Markdown con frontmatter YAML:

```yaml
---
name: nombre-del-skill
description: Una descripción concisa de qué hace el skill
trigger: "palabras clave que activan el skill"
---

# Sección principal

Aquí van las instrucciones para el agente...
```

### Ubicación

Los skills se almacenan en:

```
.github/skills/
o
~/.copilot/skills/
```

### Herramienta para crear skills

Usa el skill **`skill-creator`** para generar skills de forma estructurada:

```bash
/skills
# Luego selecciona skill-creator
```

El skill-creator:
- ✅ Valida la estructura y frontmatter
- ✅ Genera skills listos para usar
- ✅ Documenta patrones de uso automáticamente

### Información necesaria para crear un skill

Para crear un nuevo skill necesitas definir:

1. **Propósito**: ¿Qué debe hacer tu skill?
2. **Triggers**: ¿Cuándo debería activarse? (palabras clave, contexto)
3. **Resultado esperado**: ¿Qué logra al finalizar?
4. **Pasos**: Flujo claro de ejecución
5. **Integración**: ¿Usa CLI tools? ¿GitHub? ¿APIs externas?

---

## Análisis: Skill `us-refinement`

### 📋 Propósito

Refina raw user stories **antes** de que pasen a diseño técnico o `/sdd-new`. El objetivo es resolver ambigüedad en el requerimiento, no después en código.

### 🎯 Triggers configurados

El skill se activa automáticamente en estos casos:

- User story pegada con petición de refinar/clarificar
- Referencia a issue de GitHub para refinamiento (ej: "refina la issue #123")
- Story a punto de convertirse en spec sin criterios de aceptación explícitos
- Menciones de: "criterios de aceptación", "acceptance criteria", "INVEST", "ready for dev", "definición de terminado"

### 🔄 Flujo de 5 pasos

**Step 0: Detectar fuente**
- ¿Es texto pegado directamente? → Usar directamente
- ¿Es referencia a GitHub? → Fetch con `gh issue view <number>`

**Step 1: Analizar contra INVEST**
- Independent (independencia)
- Negotiable (negociable, no sobre-especificado)
- Valuable (valor explícito)
- Estimable (estimable)
- Small (tamaño apropiado)
- Testable (testeable)

**Step 2: Preguntar lo faltante (flexible)**
- Acceptance criteria
- Edge cases
- Dependencies
- Technical scope

**Nota importante**: Es un gate flexible. Si el usuario dice "adelante de todas formas", procede pero documenta todo como **assumptions**.

**Step 3: Generar la user story refinada**

Formato estructurado:
```markdown
## [Story title]

**As a** [rol]
**I want** [acción]
**So that** [valor/beneficio]

### Acceptance criteria
- Scenario 1 (happy path)
- Scenario 2+ (edge cases)

### Dependencies
### Technical scope
### Assumptions / pending
```

**Step 4: Escribir de vuelta a GitHub (si aplica)**
- Comentario (default, no-destructivo) ← **Recomendado**
- Reemplazar body completo (destructivo, requiere confirmación explícita)

**Step 5: Cierre**
- Confirmar refinamiento
- Ofrecer ajustes o splits
- Listo para `/sdd-new` si el usuario lo desea

### ✅ Lo que funciona excelentemente

1. **Prevención de problemas** - Resuelve ambigüedad ANTES, no después en código
2. **Flexibilidad inteligente** - El gate flexible evita fricción sin sacrificar calidad
3. **Bilingüismo respetado** - Instrucciones en inglés (eficientes), respuestas en idioma del usuario
4. **Integración GitHub nativa** - Usa `gh` CLI, no destructivo (comments, no edits)
5. **Estructura INVEST** - Basado en mejores prácticas conocidas de product management

### 🤔 Mejoras sugeridas

**1. Guardar refinamiento local**
```bash
# Agregar a Step 4:
- Guardar a archivo .md local (útil para auditoría, no requiere GitHub auth)
```

**2. Versionado de refinamientos**
```bash
# Si la story cambia, ¿cómo sé que fue refinada?
# Sugerencia: agregar "refinement_version" en comments de GitHub
```

**3. Template de split automático**
```bash
# Si detectas que debe dividirse, genera automáticamente
# plantillas para las historias derivadas
```

**4. Validación de criterios**
```bash
# Detectar si los criterios de aceptación son realmente
# Given/When/Then en lugar de prosa vaga
```

---

## Registrar Skills en tu proyecto

### Comando para registrar

```bash
/skills
# Luego usa skill-registry para actualizar el registro oficial
```

El `skill-registry` hace visible el skill en:
- `/skills` list
- Documentación del proyecto
- Autocompletado del CLI

---

## Recomendaciones

### 🚀 Para tu proyecto

1. **Registra `us-refinement`** como skill oficial con `skill-registry`
2. **Documenta triggers claros** para que los miembros del equipo sepan cuándo usarlo
3. **Integra en tu flujo de issues** - Agrega un template de issue que mencione "/skills us-refinement"
4. **Versiona el skill** - Usa git para trackear cambios en `.github/skills/`

### 💡 Para crear nuevos skills

1. **Identifica patrones recurrentes** en tu workflow
2. **Define triggers específicos** (no demasiado amplios)
3. **Escribe pasos claros** (4-6 pasos es el sweet spot)
4. **Testea con casos reales** antes de registrar
5. **Documente ejemplos** de uso en el skill mismo

---

## Recursos

- **GitHub Copilot CLI Docs**: https://docs.github.com/copilot/how-tos/use-copilot-agents/use-copilot-cli
- **Comandos disponibles**: Escribe `/help` en Copilot CLI
- **Tu skill actual**: `SKILL.md` (us-refinement)

---

## Notas

- Los skills respetan el idioma del usuario, no importa en qué idioma estén escritos
- Usa `gh` CLI para todas las integraciones GitHub
- Los skills son LLM-first: instrucciones claras son más importantes que la sintaxis
- Documenta assumptions y decisiones de diseño en el skill para futuro mantenimiento
