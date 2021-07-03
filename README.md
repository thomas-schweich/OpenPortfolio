# [WIP] OpenPortfolio
[![Code style: black](https://img.shields.io/badge/code%20style-black-000000.svg)](https://github.com/psf/black)

## OpenPortfolio | An Open Source Finance Tracker and Visualizer

OpenPortfolio will be a data-source agnostic portfolio tracker and visualizer. It is in the __earliest__ phase of development (pre-alpha/work-in-progress).

### Planned Features

- The initial goal will be to allow tracking portfolio performance and allocation based on a transaction log and historical market data. 
- Data will initially be available through upload of data files and via manual entry.
    - Eventually, users should have the ability to integrate with an api of their choosing for data collection. 
- Users will also have the ability to keep basic data they enter or collect on their device (either using persistent browser storage, using file uploads and downloads, or both).
- Users should have the ability to create "sub-porfolios" or "buckets" of investments which can be focused independently while also factoring into an aggregate "total portfolio" which is rendered similarly.

### Software Stack

#### Backend

- The API will use a Flask webserver to serve Vega-Lite JSON specifications and a single main webpage.
    - Production webserver and static asset server TBD.
- Vega-Lite JSON specifications could be created directly and served as static assets.
    - However, generating the specifications using the Altair Python library coupled with well-tuned template caching mechanisms may prove to be more flexible.

#### Frontend

- Vega Lite specifications will be rendered as SVG charts using VegaEmbed.
- Charts will be displayed in a dashboard format. 
- For the sake of simplicity, the frontend will seek to rely on the Reactive Vega stack as heavily as possible for *all* functionality (the webpage could even be rendered almost entirely as an SVG--we live in the future!).
    - Form elements will probably still need to exist as HTML, but reacting to their inputs can be automated using the Vega stack.
- If the Reactive Vega stack proves unsuitable for any portion of the site, Vue.js would be the first choice for an MVC framework. Vanilla JavaScript is also always an option.

## Contributing

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://github.com/thomas-schweich/OpenPortfolio)

Click the badge above to access the containerized (Ubuntu 20.04) development environment for OpenPortfolio in GitPod (an in-browser, VSCode-based, online development environment). 

Contribution guidelines are not yet established. As a result, I'm not yet actively seeking contributions. This should change in the near future.
