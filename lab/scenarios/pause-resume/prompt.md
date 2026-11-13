BottegaStack lab scenario: pause-resume. Work non-interactively; never ask the
user and never push, merge, or open a PR.

The run title is exactly "Lab pause-resume", so its slug is lab-pause-resume.

1. Run `maestro start "Lab pause-resume"`.
2. Pause it: `maestro report --close lab-pause-resume --playbook pause --risk low --outcome paused`.
3. Resume it: `maestro resume lab-pause-resume`.
4. Confirm the paused marker is gone, then close it for real:
   `maestro report --close lab-pause-resume --playbook pause --risk low --outcome rejected`.
5. Finish with a one-line summary.
