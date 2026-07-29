# Personal Preferences

## Python

- Prefer less helper functions when possible. **Never** use helpers to define 1-2 line functions just for reusability. This easily causes bloat and makes the code harder to navigate.
- Organize code such that (generally speaking) public variables are listed at the top of file, followed by public classes, public functions, and finally private functions and classes. Use `from __future__ import annotations` if necessary.
- Organize code such that (generally speaking) semantically relevant code is grouped together. It may not always be possible to follow both this and the previous formatting principle, in which case you should use your best judgment on what is most readable.
- `uv` should be used as the default package manager for all projects unless otherwise specified.
- Prefer absolute to relative imports everywhere.
- Do NOT use tuples that are longer than 2 elements unless it is self-evident as to what the tuple elements represent.
- Do NOT export explicitly in a module's `__init__.py` unless asked to.

## Testing

- If writing `pytest` tests, structure the `tests` directory similarly to the source code directory if possible. This makes it easier to find and run tests for target codepaths.
- Test only public surfaces. End-to-end tests are most important and unit tests are least important. By default, ship just a few end-to-end tests to confirm that the expected behavior is happening on common and edge case inputs.
- Before writing tests for large structural changes in the codebase, you should consult a review agent to ensure that your tests are appropriately scoped and robust to shifts in the API or behavior of the codebase.

## Communication Style

- The following preferences should only be followed in your **final** output when conversing with the human user/reader. Ignore these and default to normal conversational style when communicating with other agents.
- Prioritize elegance and succinctness. Being able to instantly understand the direction and intent of your work/main point is more important than receiving a detailed explanation of every implementation detail, as the user can additionally always ask you to dive deeper into specific points in your answer that they're interested in.
- You should draw on 3blue1brown's videos as a good source of inspiration for communication style.
- You can also think about good communication from the perspective of achieving high compression ratio, where you want to maximize the amount of meaningful information conveyed while minimizing the tokens outputted.
- Push back frequently and often. I want to hear your opinions on how to best approach the problem at hand, not just blindly following my instructions, which could be suboptimal.

## General preferences

- If asked to do too much work at once, stop and state that clearly.
- When running code review, use a subagent that does not have access to the implementation agent's conversation history. The idea is that the review agent should be able to perform its job without being biased by previous design choices. The code review agent should additionally always provide **at least one** fully unique alternative implementation that may be more elegant or intuitive than the current implementation. The implementation agent should decide whether to switch implementations.
- After writing/changing significant portions of code, use the code debloat skill.

# Autoresearch guide

We use modal to run research jobs that require computing acceleration (training deep learning models, running inference, etc.). The following skills provide guidance in this regard.

- **`$modal-basic-skills`**: foundational Modal platform knowledge
- **`$modal-gpu-dev`**: launch interactive GPU sandboxes for debugging and prototyping
- **`$modal-gpu-experiment`**: write and run training apps for experiments
- **`$sub-agents`**: orchestrate parallel agents across multiple GPUs
- **`$baremodal-workstation`**: use the persistent bare-metal workstation for small, cheap experiments; use hosted Modal for larger compute or full Modal functionality
