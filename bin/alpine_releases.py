#!/usr/bin/env python
import sys
from argparse import ArgumentParser
from datetime import date

import pandas


def version_sort(versions: list[str]):
    return sorted(versions, key=lambda v: list(map(int, v.split('.'))))


def get_releases(supported: bool = False):
    print('Fetching latest alpine releases ...', file=sys.stderr)
    df = pandas.read_html('https://alpinelinux.org/releases/')[0][1:]
    if supported:
        support_date = df['End of support'].str.extract('(\d{4}-\d{2}-\d{2})', expand=False)
        df = df[support_date.apply(date.fromisoformat) > date.today()]

    df['releases'] = df['Minor releases'].str.split('|')
    df['releases'] = df['releases'].apply(lambda row: [x.strip() for x in row if x.strip()])
    df['releases'] = df['releases'].apply(lambda row: version_sort(row)[-1])
    return df['releases'].sort_values().to_list()


if __name__ == '__main__':
    parser = ArgumentParser()
    parser.add_argument('--supported', action='store_true')
    args = parser.parse_args()
    for release in get_releases(supported=args.supported):
        print(release)

