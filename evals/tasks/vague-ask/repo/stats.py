def mean(xs):
    return sum(xs) / len(xs)


def median(xs):
    s = sorted(xs)
    n = len(s)
    return s[n // 2] if n % 2 else (s[n // 2 - 1] + s[n // 2]) / 2


def percentile(xs, p):
    s = sorted(xs)
    return s[min(len(s) - 1, int(p / 100 * len(s)))]


def summary(xs):
    return {"mean": mean(xs), "median": median(xs), "p90": percentile(xs, 90), "p99": percentile(xs, 99)}
