---
name: arch-review
description: Conduct an evidence-based architecture review with parallel read-only subagents, one per architecture aspect, then verify and consolidate their findings. Use when the user explicitly requests an architecture review or invokes arch-review; do not use for ordinary code review.
---

# Architecture Review

Review a repository, branch, diff, or scoped path against the architecture principles below. Delegate each aspect to a separate read-only subagent, then have the main agent validate and combine the results into one report.

This is an assessment workflow. Do not edit implementation code, specifications, tests, configuration, or issue trackers unless the user separately asks for changes after reviewing the report.

## Establish the review target

Honor the scope and comparison baseline in the user's request. Apply repository instruction files and relevant specifications before judging the code.

If the user invokes the skill without identifying a target:

1. Review staged and unstaged working-tree changes.
2. If the working tree is clean, ask whether to review the current branch against its base or conduct a repository-wide review.

For a diff review, distinguish architecture problems introduced or materially worsened by the change from pre-existing conditions. Report pre-existing conditions only when they are necessary to understand the changed code, and label them clearly.

## Delegate the review

Spawn one read-only subagent for each architecture aspect below. Run them in batches that respect the available concurrency limit. Give every subagent:

- the exact review target and comparison baseline;
- relevant repository instructions and specifications, or directions to read them;
- exactly one architecture aspect from this skill;
- permission to inspect code, tests, schemas, migrations, and history as needed, but not to edit anything;
- the required result format below.

Keep each subagent focused on its assigned aspect. It may mention another aspect only to explain an architectural dependency; the main agent owns cross-aspect synthesis.

If subagents are unavailable, perform the same aspect-by-aspect review sequentially and disclose that limitation in the report.

### Required subagent result

Each subagent must return:

1. **Verdict:** `pass`, `findings`, or `not applicable`.
2. **Findings:** only evidence-backed issues, each containing:
   - concise title;
   - severity: `high`, `medium`, or `low`;
   - confidence: `high`, `medium`, or `low`;
   - file and line reference;
   - current design and why it conflicts with the assigned principle;
   - concrete architectural consequence;
   - recommended structural direction, without implementing it;
   - whether the issue is localized or cross-cutting.
3. **Positive evidence:** architecture in the reviewed scope that follows the principle and should be preserved.
4. **Coverage notes:** what was inspected and any limitations.

Do not invent a finding to fill the category. Do not report formatting preferences, speculative future needs, or a generic best practice without a concrete consequence in the reviewed code.

## Architecture aspects

### 1. Cohesive responsibilities and task-oriented objects

- Avoid function soup: modules full of private helpers supporting one or two entry points.
- Put logically related behavior in a class with a real job and clear responsibilities.
- Do not merely turn related functions into static methods.
- Prefer a fresh operation or engine instance for each request, analysis, reconciliation, or background job.
- Let that instance retain scope and intermediate state instead of repeatedly passing the same identifiers and working dictionaries.
- Avoid application-wide, always-on service instances for isolated units of work.
- Registries hold classes or factories, not live mutable instances.
- Keep standalone functions for genuinely reusable, context-free logic.

### 2. Method size, composition, and separation of concerns

- Treat methods or branches spanning hundreds of lines as architectural warning signs, not as a line-count violation by itself.
- A method should perform one coherent, verifiable step.
- Compose large workflows from named phases or cohesive collaborators.
- Keep orchestration methods short enough that their sequence is readily understandable.
- Keep boundary-level exception handling separate from focused calculation and mutation steps.
- Split genuinely distinct work into collaborators such as a calculator, evidence writer, reader, or lifecycle operation rather than accumulating a god object.

### 3. Entity ownership and the relational data contract

- Treat SQLAlchemy entities as the contract between the application and relational data.
- Put meaningful query methods on the primary entity being queried.
- Put lifecycle operations and state transitions on the entity that owns them.
- Encapsulate multi-field housekeeping inside entity methods.
- Allow consumers to perform trivial assignments, but not to reproduce domain state transitions field by field.
- Keep entity methods consumer-agnostic: they should express domain meaning without knowing whether a route, dashboard, CLI, or task calls them.
- Operations may own locking and transaction orchestration while entities own detailed state mutation.

### 4. Layer boundaries

- View modules should primarily contain views, not substantial ORM queries or domain operations.
- System-level actions belong on an owning entity or operation object, not in a route merely because the route initiated them.
- Templates render prepared context; they should not calculate business concepts or interpret complex internal structures.
- Simple presentation conditions are acceptable when based on view-provided values.
- Services and operations orchestrate domain objects, engines, and query components; they should not become catch-alls for work with a clearer owner.
- Scope declarations and expressions near the component that owns them so their purpose is unambiguous.

### 5. Purposeful abstraction without indirection

- Reject facades, compatibility adapters, and pass-through methods that exist only to preserve an obsolete internal interface.
- Update callers to use the real object directly.
- Avoid module-private wrappers around methods that belong on the public class.
- Keep single-use logic inline unless it represents a cohesive responsibility.
- Do not multiply layers during a refactor or create one-method modules without a real boundary.
- Adapters are appropriate at genuine external or variant boundaries, such as storage backends, document extractors, and processor implementations. Distinguish these from internal migration shims.
- Prefer extending established infrastructure over creating a parallel mechanism.

### 6. Explicit domain data and typed representations

- Prefer explicit result objects or dataclasses over loosely structured tuples and transient dictionaries passed between phases.
- Keep numeric values in their numeric types while calculating and sorting; serialize only at the output boundary.
- Use structured composite keys instead of delimiter-packed strings.
- Use arrays or lists instead of concatenating values only to split them later.
- Represent missing and synthetic concepts explicitly instead of overloading display strings as control-flow sentinels.
- Keep business meaning separate from presentation encoding.
- Make constructor inputs and return values reveal their expected types.
- Do not add tuple-like or legacy-interface compatibility shims during an internal migration.

### 7. Query boundaries and scalability

- Do not issue ORM queries per row inside a loop; use batched operations.
- Explicitly eager-load relationships that consumers will access with `selectinload` or `joinedload`.
- Prefer joins or batched aggregation over correlated scalar queries that execute per result row.
- Query methods should return the complete relational contract their caller needs.
- Centralize infrastructure-level dataset handling such as connections, storage adapters, credentials, and temporary views.
- Keep domain-specific SQL in focused query components that return typed results.
- Operations orchestrate queries rather than constructing scattered SQL themselves.

### 8. Persistence integrity, identity, and lifecycle modeling

- Avoid redundant foreign keys, columns, and derived fields that must remain synchronized.
- Persist a value only when it represents an independent fact.
- Derive display-only groupings at runtime rather than treating them as calculation identity.
- Use stable relational or content identity instead of filenames, labels, or presentation values.
- Use enums or constraints for known finite value sets instead of repeated string literals.
- Preserve immutable source data and historical or event records when auditability matters.
- Ask of every field, table, or relationship: what independent domain fact does it represent?

### 9. Generic durable core and specialized edges

- Keep the durable data model processor- or provider-agnostic where practical.
- Use a stable application-facing interface with specialized implementations or subclasses.
- Avoid speculative generality, but leave a clean seam for the next real implementation.

### 10. Tests as architecture contracts

- Test every entity query, action, event, and state transition directly in the model test suite.
- Do not treat route or consumer coverage as a substitute for testing the relational contract.
- Test engines, calculators, and other cohesive components independently from their orchestrators.
- Cover happy paths, failures, edge cases, and relationship-loading behavior.
- Prefer real database queries where practical.
- Use focused fixtures and entity factory/fake methods rather than repetitive setup graphs and broad teardown.
- Do not add production branches that detect tests; mock external boundaries such as task enqueueing instead.
- Avoid tautological tests that merely restate a declaration without exercising behavior.

### 11. Domain language, locality, and documentation

- Names should describe the actual operation rather than a broader or vaguer concept.
- Avoid overusing generic terms such as `service` or `context` when a more precise domain name exists.
- Keep related declarations close to their use.
- Comment relational fields whose lifecycle meaning is not intuitive.
- Document important mental models and surprising materialization, temporary-table, or lifecycle behavior.
- Keep terminology consistent across models, statuses, UI, and code.

### 12. Transactional and operational integrity

- Keep transaction ownership and commit boundaries explicit.
- Make multi-record lifecycle transitions atomic when partial completion would create invalid state.
- Put locks at the orchestration boundary while keeping entity actions responsible for consistent field changes.
- Design background operations to be idempotent where retries are expected.
- Queue work in a way that cannot observe uncommitted or incomplete state.
- Preserve history before replacing or deactivating active records when the domain requires auditability or restoration.
- Do not overbuild concurrency machinery for hypothetical scale, but avoid choices that make a later safe transition unnecessarily difficult.

## Main-agent synthesis

Wait for every assigned aspect to finish. Then:

1. Verify each proposed finding against the referenced code and applicable specifications.
2. Remove unsupported, purely stylistic, out-of-scope, or duplicate findings.
3. Combine findings with the same architectural root cause rather than reporting each symptom separately.
4. Preserve useful disagreement between aspects when it exposes a real tradeoff; explain the tradeoff instead of silently choosing one conclusion.
5. Distinguish localized cleanup from a cross-cutting redesign.
6. Rank findings by consequence:
   - `high`: creates systemic correctness, data-integrity, scalability, or change-safety risk and likely requires architectural redesign;
   - `medium`: materially harms ownership, testability, maintainability, or performance but can be corrected within an established boundary;
   - `low`: limited architectural drift with a concrete cost, suitable for focused cleanup.
7. Do not recommend a broad rewrite when a smaller ownership or boundary correction resolves the issue.

## Final report

Write the report to the user's requested destination. If none is requested, return it in the conversation.

Use this structure:

```markdown
# Architecture Review

## Scope and baseline

## Executive summary

## Findings

### High severity

### Medium severity

### Low severity

## Cross-cutting themes

## Architecture aspects assessed

| Aspect | Verdict | Summary |
| --- | --- | --- |

## Positive patterns to preserve

## Recommended sequence

## Coverage and limitations
```

For each finding, include evidence, consequence, and structural direction. The recommended sequence should describe dependencies among changes, not silently authorize implementation.

End with a compact accounting of how many subagent findings were accepted, merged, downgraded, or rejected during main-agent verification.
