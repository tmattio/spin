(name bs-react)
(description "React application in Reason")

(config project_name
  (input (prompt "Project name")))

(config project_slug
  (input (prompt "Project slug"))
  (default (slugify :project_name))
  (rules
    ("The project slug must be lowercase and contain ASCII characters and '-' only."
      (eq :project_slug (slugify :project_slug)))))

(config project_snake
  (default (snake_case :project_slug)))

(config project_description
  (input (prompt "Description"))
  (default "A short, but powerful statement about your project"))

(config username
  (input (prompt "Name of the author")))

(config css_framework
  (select
    (prompt "Which CSS framework do you use?")
    (values TailwindCSS None))
  (default None))

(config ci_cd
  (select
    (prompt "Which CI/CD do you use?")
    (values Github None))
  (default Github))

(ignore 
  (files config/postcss.config.js config/tailwind.config.js)
  (enabled_if (neq :css_framework TailwindCSS)))

(ignore
  (files .github/*)
  (enabled_if (neq :ci_cd Github)))

(post_gen
  (actions 
    (run yarn install))
  (message "🎁  Installing packages. This might take a couple minutes.")
  (enabled_if (not (run which yarn))))

(post_gen
  (actions 
    (run npm install))
  (message "🎁  Installing packages. This might take a couple minutes.")
  (enabled_if (run which yarn)))

(example_commands
  (commands 
    ("yarn start" "Start the development server.")
    ("yarn build" "Bundle the app into static files for production.")
    ("yarn test" "Start the test runner."))
  (enabled_if (not (run which yarn))))

(example_commands
  (commands 
    ("npm start" "Start the development server.")
    ("npm build" "Bundle the app into static files for production.")
    ("npm test" "Start the test runner."))
  (enabled_if (run which yarn)))
