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
