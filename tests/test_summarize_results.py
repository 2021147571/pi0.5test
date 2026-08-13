from scripts.summarize_results import PATTERNS, last_match


def test_official_style_summary() -> None:
    text = """
    Final results:
    Total episodes: 10
    Total successes: 9
    Overall success rate: 0.9000
    """
    assert last_match(text, PATTERNS["total_episodes"], int) == 10
    assert last_match(text, PATTERNS["total_successes"], int) == 9
    assert last_match(text, PATTERNS["success_rate"], float) == 0.9


def test_missing_values_return_none() -> None:
    assert last_match("no metrics", PATTERNS["total_episodes"], int) is None


def test_openpi_libero_log_style() -> None:
    text = """
    INFO:root:# successes: 8 (80.0%)
    INFO:root:Current total success rate: 0.8
    INFO:root:# successes: 9 (90.0%)
    INFO:root:Total success rate: 0.9
    INFO:root:Total episodes: 10
    """
    assert last_match(text, PATTERNS["total_episodes"], int) == 10
    assert last_match(text, PATTERNS["total_successes"], int) == 9
    assert last_match(text, PATTERNS["success_rate"], float) == 0.9
