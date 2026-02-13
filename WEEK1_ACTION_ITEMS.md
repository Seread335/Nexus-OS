# Nexus OS — Action Items & 3-Week Sprint Plan
**Week 1 of 3 — Critical Path to v0.1**

---

## 🎯 THIS WEEK'S PRIORITIES

### **CRITICAL (Must Succeed)**

- [ ] **TEST ISO IN QEMU** ← START THIS IMMEDIATELY
  - Time: 2-3 hours
  - Owner: @infra-engineer
  - Steps:
    ```bash
    cd d:\Nexus OS
    # Build ISO on Linux (WSL2) or Linux machine
    bash scripts/build_iso.sh ./iso_output
    
    # Boot in QEMU
    qemu-system-x86_64 -m 4G -cpu host ./iso_output/nexus-*.iso
    
    # Verify:
    # ✓ Grub menu appears
    # ✓ Linux boots
    # ✓ You can login (root password?)
    # ✓ Cerberus systemd service exists
    # ✓ nexus-recon command works
    ```
  - If FAILS: Debug build/boot issues (add to risk log)
  - If PASSES: Mark as ✅ and proceed with confidence

- [ ] **RUN PYTEST LOCALLY**
  - Time: 1-2 hours
  - Owner: @qa-engineer
  - Steps:
    ```bash
    cd d:\Nexus OS
    pip install pytest
    pytest tests/ -v --tb=short
    ```
  - Expected: 80-90% tests pass (some may skip on Windows)
  - If FAILS: Document failures, prioritize fixes

- [ ] **REVIEW CODE QUALITY**
  - Time: 2 hours
  - Owner: @tech-lead
  - Checklist:
    - [ ] No syntax errors (python -m py_compile)
    - [ ] Logging present
    - [ ] Error handling complete
    - [ ] Type hints used
    - [ ] Comments clear
  - Grade: ✅ Should be 7-8/10

---

### **HIGH PRIORITY (This Week, If Time)**

- [ ] **ADD BASIC INTEGRATION TEST**
  - Time: 2-3 hours
  - Owner: @qa-engineer
  - Goal: Test Cerberus + Ollama together
  - File: `tests/test_e2e_cerberus_ollama.py`
  - Pseudo-code:
    ```python
    def test_cerberus_calls_ollama_mock():
        # Start Cerberus in thread
        # Mock Ollama API
        # POST /api/ask to Cerberus
        # Verify response
        assert response == "Mock LLM reply"
    ```

- [ ] **DOCUMENT CURRENT BLOCKERS**
  - Time: 1 hour
  - Owner: @project-lead
  - Create: `BLOCKERS.md`
  - Format:
    ```markdown
    ## Critical Blockers (Release-blocking)
    - [ ] ISO boot test (PENDING)
    - [ ] Test coverage (PENDING)
    
    ## High Blockers (Important)
    - [ ] PKGBUILD checksums (PENDING)
    - [ ] Context encryption (PENDING)
    
    ## Medium Blockers (Should Fix)
    - [ ] Audit log signing (PENDING)
    ```

---

## 📊 STATUS TRACKING

### **Daily Standup Template**

Each day, fill this out:

```
DATE: ___________
ENGINEER: ___________

COMPLETED (Yesterday):
- [ ] Task 1 - X% done
- [ ] Task 2 - X% done

IN PROGRESS (Today):
- [ ] Task 1 - X% done, blocker?: Y/N
- [ ] Task 2 - X% done, blocker?: Y/N

BLOCKED:
- Task: ___________
  Reason: ___________
  Help needed: ___________

NEXT (Tomorrow):
- [ ] Task 1
- [ ] Task 2

RISKS:
- Risk 1 (probability: X, impact: Y)
```

---

## 🔍 CODE REVIEW CHECKLIST

Before committing any new code:

- [ ] ✅ **Syntax**: No errors (`python -m py_compile`)
- [ ] ✅ **Tests**: New code has corresponding tests
- [ ] ✅ **Logging**: Important operations logged
- [ ] ✅ **Errors**: Exceptions caught and handled
- [ ] ✅ **Types**: Type hints present (PEP 484)
- [ ] ✅ **Comments**: Complex logic explained
- [ ] ✅ **Security**: No hardcoded secrets, no SQL injection
- [ ] ✅ **Performance**: No obvious bottlenecks
- [ ] ✅ **Docs**: README/docstrings updated if needed

---

## 📈 METRICS TO TRACK

Track these daily:

```
===== CODE METRICS =====
Python files:        [ ] 7 (should be stable)
Test files:          [ ] 7+ (growing)
Test coverage:       [ ] 5% → target 50%
Lines of code (src): [ ] ~1000 (should be stable)
Lines of code (test):[ ] ~300+ (should grow)

===== QUALITY METRICS =====
Syntax errors:       [ ] 0
Test pass rate:      [ ] ?% (start baseline)
Documentation:       [ ] 15 files

===== DEPLOYMENT READINESS =====
ISO tested?          [ ] NO (CRITICAL)
Checksums added?     [ ] NO
Tests passing?       [ ] ~80% (on Windows)
```

---

## 🎓 TEAM RESPONSIBILITIES

### **Infrastructure Engineer** (@infra)
- [ ] Build + test ISO this week
- [ ] Report boot success/failure
- [ ] Debug any boot issues
- [ ] Document ISO build process

### **QA/Test Engineer** (@qa)
- [ ] Run pytest locally
- [ ] List failing tests
- [ ] Write integration test
- [ ] Estimate effort to 50% coverage

### **Backend Engineer** (@backend)
- [ ] Review Cerberus code
- [ ] Review nexus-recon code
- [ ] Fix any issues found
- [ ] Add encryption (week 2)

### **Tech Lead** (@lead)
- [ ] Coordinate team
- [ ] Review architecture
- [ ] Prioritize blockers
- [ ] Make release decision

---

## 🚀 SUCCESS CRITERIA FOR WEEK 1

**End of Week 1, You Should Have:**

- [ ] ✅ ISO boots in QEMU (or clear error to fix)
- [ ] ✅ Pytest runs locally (baseline established)
- [ ] ✅ 80%+ of existing tests pass
- [ ] ✅ No critical bugs found
- [ ] ✅ Short integration test written
- [ ] ✅ Blocker list documented
- [ ] ✅ Team confidence: 6/10 → 7/10

**If All Pass**: Proceed to Week 2  
**If Some Fail**: Extend Week 1 by 2-3 days

---

## 💡 TIPS FOR SUCCESS

1. **Parallel Work**: Don't wait for ISO to finish before running tests
   - ISO build: ~20 min
   - While building: run pytest, write tests
   
2. **Fail Fast**: If ISO doesn't boot, investigate immediately
   - Is pacman config wrong?
   - Is profile.def.sh wrong?
   - Is customize_airootfs.sh failing?
   - Spending 2 hours debugging saves 10 hours later

3. **Document Everything**: ISO boot failure? Document it
   - What failed?
   - Error message?
   - Recovery steps?
   - Helps next person

4. **Celebrate Wins**: ISO booted? Good job!
   - You just cleared the biggest blocker
   - Tests passing? Great!
   - Document success = morale boost

5. **Risk Management**: Found a risk?
   - Document it NOW
   - Plan mitigation
   - Check daily for change
   - Act early if probability increases

---

## 📲 COMMUNICATION

### **Daily Updates**
- Time: 10 AM (or daily standup time)
- Format: 3-bullet summary (done, doing, blocked)
- Owner: Each engineer

### **Weekly Retro**
- Time: Friday 3 PM (or end of week)
- Duration: 30 min
- Owner: Tech lead
- Format:
  - What went well?
  - What went bad?
  - What changed this week?
  - What's priority next week?

### **If Blocked**
- Mention immediately (don't wait)
- CC: Tech lead
- Format: "Task X blocked by Y, need help from Z by DATE"

---

## 🎯 WEEK 1 SUCCESS METRICS

| Metric | Target | Success |
|--------|--------|---------|
| ISO boots | YES | ✅ Critical |
| Tests run | YES | ✅ Critical |
| No major bugs | TBD | ✅ Goal |
| Integration test added | 1+ | ✅ Goal |
| Documentation updated | 0+ | ✅ Nice |
| Team velocity | N/A | ✅ 60% capacity |

---

## 🏁 END-OF-WEEK REVIEW TEMPLATE

**Friday Afternoon (or end of week):**

```markdown
# Week 1 Review — Nexus OS

## What We Accomplished
- [ ] ISO tested: YES/NO/PARTIAL
- [ ] Tests run: YES/PARTIAL/NO
- [ ] Integration test: YES/NO
- [ ] Issues found: 0/1/2+/5+
- [ ] Blockers removed: 0/1/2

## What We Learned
- Lesson 1: ___________
- Lesson 2: ___________

## Risks Identified
- Risk 1 (probability: LOW/MED/HIGH, impact: LOW/MED/HIGH)
- Risk 2

## Week 2 Priorities
1. ___________
2. ___________
3. ___________

## Team Health
- Morale: 😞 / 😐 / 🙂 / 😄
- Velocity: Low / Medium / High (vs planned)
- Blockers: None / Manageable / Critical

## Release Confidence
- Week 1 start: 5/10
- Week 1 end: ?/10 (estimate)
- Probability v0.1 in 3 weeks: ?%
```

---

## 🎁 YOU HAVE EVERYTHING NEEDED

✅ Code is written  
✅ Tests are written  
✅ Docs are extensive  
✅ Team is ready  
✅ Architecture is sound  

**Now just execute the plan.**

This week: Test + measure  
Week 2: Fix + secure  
Week 3: Document + release  

**v0.1 by end of March = ACHIEVABLE.** 🚀

---

**Questions?** Check [FINAL_VERDICT.md](FINAL_VERDICT.md) or [DETAILED_ASSESSMENT.md](DETAILED_ASSESSMENT.md)

