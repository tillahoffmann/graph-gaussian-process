import cmdstanpy
import logging


master_doc = "README"
extensions = [
    "matplotlib.sphinxext.plot_directive",
    "myst_nb",
    "sphinx.ext.doctest",
    "sphinx.ext.napoleon",
    "sphinx.ext.autodoc",
    "sphinx.ext.intersphinx",
    "sphinxcontrib.stan",
]
project = "gptools"
napoleon_custom_sections = [("Returns", "params_style")]
plot_formats = [
    ("png", 144),
]
html_theme = "sphinx_rtd_theme"
html_sidebars = {}
exclude_patterns = ["docs/_build", "docs/jupyter_execute", ".pytest_cache", "playground"]

# Configure autodoc to avoid excessively long fully-qualified names.
add_module_names = False
autodoc_typehints_format = "short"

intersphinx_mapping = {
    "python": ("https://docs.python.org/3", None),
    "numpy": ("https://numpy.org/doc/stable/", None),
    "scipy": ("https://docs.scipy.org/doc/scipy/", None),
    "matplotlib": ("https://matplotlib.org/stable", None),
    "torch": ("https://pytorch.org/docs/stable/", None),
}

source_suffix = {
    '.rst': 'restructuredtext',
    '.ipynb': 'myst-nb',
}

cmdstanpy_logger = cmdstanpy.utils.get_logger()
for handler in cmdstanpy_logger.handlers:
    handler.setLevel(logging.WARNING)

nb_execution_mode = "off"
myst_enable_extensions = [
    "amsmath",
    "dollarmath",
]
myst_dmath_double_inline = True
