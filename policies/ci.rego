package ci

default allow := false

threshold := 20  # Minimum overall coverage %

# Function: fetches commit list from GitHub
get_commits() := commits if {
    resp := http.send({
        "method": "get",
        "url": sprintf("https://api.github.com/repos/%s/commits?sha=%s&per_page=100", [input.repo, input.head]),
        "headers": {
            "authorization": sprintf("token %s", [input.token]),
            "accept": "application/vnd.github+json",
        },
        "timeout": "10s",
    })
    resp.status_code == 200
    json.unmarshal(resp.body, commits)
}

# Rule: all commits must be verified
commits_ok if {
    commits := get_commits()
    not exists_unverified(commits)
}

exists_unverified(commits) if {
    some c in commits
    not c.verification.verified
}

# Rule: total test coverage meets threshold
coverage_ok if {
    raw := input.coverage.total_test_coverage
    pct := to_number(trim(raw, "%"))
    pct >= threshold
}

# Final decision
allow if {
    commits_ok
    coverage_ok
}
