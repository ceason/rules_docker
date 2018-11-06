# Copyright 2017 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""A rule for creating a D container image.

The signature of this rule is compatible with d_binary.
"""

load(
    "//lang:image.bzl",
    "app_layer",
)
load(
    "//cc:image.bzl",
    "DEFAULT_BASE",
    _repositories = "repositories",
)
load("@io_bazel_rules_d//d:d.bzl", "d_binary")

def repositories():
    _repositories()

def d_image(
        name,
        base = None,
        launcher = None,
        launcher_args = [],
        launcher_path = None,
        deps = [],
        layers = [],
        binary = None,
        **kwargs):
    """Constructs a container image wrapping a d_binary target.

  Args:
    binary: An alternative binary target to use instead of generating one.
    layers: Augments "deps" with dependencies that should be put into
           their own layers.
    **kwargs: See d_binary.
  """
    if layers:
        print("d_image does not benefit from layers=[], got: %s" % layers)

    if not binary:
        binary = name + "_binary"
        d_binary(name = binary, deps = deps + layers, **kwargs)
    elif deps:
        fail("kwarg does nothing when binary is specified", "deps")

    base = base or DEFAULT_BASE
    for index, dep in enumerate(layers):
        base = app_layer(name = "%s_%d" % (name, index), base = base, dep = dep)
        base = app_layer(name = "%s_%d-symlinks" % (name, index), base = base, dep = dep, binary = binary)

    visibility = kwargs.get("visibility", None)
    tags = kwargs.get("tags", None)
    app_layer(
        name = name,
        base = base,
        binary = binary,
        visibility = visibility,
        tags = tags,
        args = kwargs.get("args"),
        data = kwargs.get("data"),
        launcher = launcher,
        launcher_args = launcher_args,
        launcher_path = launcher_path,
    )
