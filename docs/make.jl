using Documenter, PowerModelsRestoration

makedocs(
    warnonly = Documenter.except(:linkcheck),
    modules = [PowerModelsRestoration],
    format = Documenter.HTML(mathengine = Documenter.MathJax()),
    sitename = "PowerModelsRestoration",
    authors = "Noah Rhodes, David Fobes, Carleton Coffrin",
    pages = [
        "Home" => "index.md",
        "Manual" => [
            "Variables" => "variables.md",
            "Constraints" => "constraints.md",
            "Data" => "data.md",
            "Form" => "form.md",
            "Problem" => "prob.md",
            "Utility Functions" => "util.md"
        ],
    ]
)

deploydocs(
    repo = "github.com/lanl-ansi/PowerModelsRestoration.jl.git",
)
