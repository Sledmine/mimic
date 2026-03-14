return { {
    address = "0x0",
    fields = { {
        address = "0x0",
        fields = { {
            address = "0x0",
            is = "int",
            metaName = "ObjectType",
            name = "type",
            offset = 0,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0x2",
            fields = { {
                address = "0x0",
                is = "int",
                name = "doesNotCastShadow",
                offset = 0,
                size = 2,
                type = "word",
                unsigned = true,
                what = "bitfield"
              }, {
                address = "0x0",
                is = "int",
                name = "transparentSelfOcclusion",
                offset = 1,
                size = 2,
                type = "word",
                unsigned = true,
                what = "bitfield"
              }, {
                address = "0x0",
                is = "int",
                name = "brighterThanItShouldBe",
                offset = 2,
                size = 2,
                type = "word",
                unsigned = true,
                what = "bitfield"
              }, {
                address = "0x0",
                is = "int",
                name = "notAPathfindingObstacle",
                offset = 3,
                size = 2,
                type = "word",
                unsigned = true,
                what = "bitfield"
              }, {
                address = "0x0",
                is = "int",
                name = "extensionOfParent",
                offset = 4,
                size = 2,
                type = "word",
                unsigned = true,
                what = "bitfield"
              }, {
                address = "0x0",
                is = "int",
                name = "castShadowByDefault",
                offset = 5,
                size = 2,
                type = "word",
                unsigned = true,
                what = "bitfield"
              }, {
                address = "0x0",
                is = "int",
                name = "doesNotHaveAnniversaryGeometry",
                offset = 6,
                size = 2,
                type = "word",
                unsigned = true,
                what = "bitfield"
              } },
            is = "struct",
            metaName = "ObjectFlags",
            name = "flags",
            offset = 2,
            size = 2,
            type = "ObjectFlags",
            what = "field"
          }, {
            address = "0x4",
            is = "float",
            name = "boundingRadius",
            offset = 4,
            size = 4,
            type = "float",
            what = "field"
          }, {
            address = "0x8",
            fields = { {
                address = "0x0",
                is = "float",
                name = "x",
                offset = 0,
                size = 4,
                type = "float",
                what = "field"
              }, {
                address = "0x4",
                is = "float",
                name = "y",
                offset = 4,
                size = 4,
                type = "float",
                what = "field"
              }, {
                address = "0x8",
                is = "float",
                name = "z",
                offset = 8,
                size = 4,
                type = "float",
                what = "field"
              } },
            is = "struct",
            metaName = "VectorXYZ",
            name = "boundingOffset",
            offset = 8,
            size = 12,
            type = "VectorXYZ",
            what = "field"
          }, {
            address = "0x14",
            fields = { {
                address = "0x0",
                is = "float",
                name = "x",
                offset = 0,
                size = 4,
                type = "float",
                what = "field"
              }, {
                address = "0x4",
                is = "float",
                name = "y",
                offset = 4,
                size = 4,
                type = "float",
                what = "field"
              }, {
                address = "0x8",
                is = "float",
                name = "z",
                offset = 8,
                size = 4,
                type = "float",
                what = "field"
              } },
            is = "struct",
            metaName = "VectorXYZ",
            name = "originOffset",
            offset = 20,
            size = 12,
            type = "VectorXYZ",
            what = "field"
          }, {
            address = "0x20",
            is = "float",
            name = "accelerationScale",
            offset = 32,
            size = 4,
            type = "float",
            what = "field"
          }, {
            address = "0x24",
            fields = { {
                address = "0x0",
                is = "int",
                name = "functionsControlColorScale",
                offset = 0,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "bitfield"
              } },
            is = "struct",
            metaName = "ObjectRuntimeFlags",
            name = "runtimeFlags",
            offset = 36,
            size = 4,
            type = "ObjectRuntimeFlags",
            what = "field"
          }, {
            address = "0x28",
            fields = { {
                address = "0x0",
                is = "int",
                metaName = "TagGroup",
                name = "tagGroup",
                offset = 0,
                size = 4,
                type = "int",
                what = "field"
              }, {
                address = "0x4",
                count = 4,
                elementSize = 1,
                elementType = "char",
                is = "ptr",
                name = "path",
                offset = 4,
                size = 4,
                what = "field"
              }, {
                address = "0x8",
                is = "int",
                name = "pathSize",
                offset = 8,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "field"
              }, {
                address = "0xc",
                fields = { {
                    address = "0x0",
                    is = "int",
                    name = "value",
                    offset = 0,
                    size = 4,
                    type = "dword",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x0",
                    is = "int",
                    name = "index",
                    offset = 0,
                    size = 2,
                    type = "word",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x2",
                    is = "int",
                    name = "id",
                    offset = 2,
                    size = 2,
                    type = "word",
                    unsigned = true,
                    what = "field"
                  } },
                is = "union",
                metaName = "TableResourceHandle",
                name = "tagHandle",
                offset = 12,
                size = 4,
                type = "TableResourceHandle",
                what = "field"
              } },
            is = "struct",
            metaName = "TagReference",
            name = "model",
            offset = 40,
            size = 16,
            type = "TagReference",
            what = "field"
          }, {
            address = "0x38",
            fields = { {
                address = "0x0",
                is = "int",
                metaName = "TagGroup",
                name = "tagGroup",
                offset = 0,
                size = 4,
                type = "int",
                what = "field"
              }, {
                address = "0x4",
                count = 4,
                elementSize = 1,
                elementType = "char",
                is = "ptr",
                name = "path",
                offset = 4,
                size = 4,
                what = "field"
              }, {
                address = "0x8",
                is = "int",
                name = "pathSize",
                offset = 8,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "field"
              }, {
                address = "0xc",
                fields = { {
                    address = "0x0",
                    is = "int",
                    name = "value",
                    offset = 0,
                    size = 4,
                    type = "dword",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x0",
                    is = "int",
                    name = "index",
                    offset = 0,
                    size = 2,
                    type = "word",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x2",
                    is = "int",
                    name = "id",
                    offset = 2,
                    size = 2,
                    type = "word",
                    unsigned = true,
                    what = "field"
                  } },
                is = "union",
                metaName = "TableResourceHandle",
                name = "tagHandle",
                offset = 12,
                size = 4,
                type = "TableResourceHandle",
                what = "field"
              } },
            is = "struct",
            metaName = "TagReference",
            name = "animationGraph",
            offset = 56,
            size = 16,
            type = "TagReference",
            what = "field"
          }, {
            address = "0x48",
            count = 40,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad5279",
            offset = 72,
            size = 40,
            what = "field"
          }, {
            address = "0x70",
            fields = { {
                address = "0x0",
                is = "int",
                metaName = "TagGroup",
                name = "tagGroup",
                offset = 0,
                size = 4,
                type = "int",
                what = "field"
              }, {
                address = "0x4",
                count = 4,
                elementSize = 1,
                elementType = "char",
                is = "ptr",
                name = "path",
                offset = 4,
                size = 4,
                what = "field"
              }, {
                address = "0x8",
                is = "int",
                name = "pathSize",
                offset = 8,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "field"
              }, {
                address = "0xc",
                fields = { {
                    address = "0x0",
                    is = "int",
                    name = "value",
                    offset = 0,
                    size = 4,
                    type = "dword",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x0",
                    is = "int",
                    name = "index",
                    offset = 0,
                    size = 2,
                    type = "word",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x2",
                    is = "int",
                    name = "id",
                    offset = 2,
                    size = 2,
                    type = "word",
                    unsigned = true,
                    what = "field"
                  } },
                is = "union",
                metaName = "TableResourceHandle",
                name = "tagHandle",
                offset = 12,
                size = 4,
                type = "TableResourceHandle",
                what = "field"
              } },
            is = "struct",
            metaName = "TagReference",
            name = "collisionModel",
            offset = 112,
            size = 16,
            type = "TagReference",
            what = "field"
          }, {
            address = "0x80",
            fields = { {
                address = "0x0",
                is = "int",
                metaName = "TagGroup",
                name = "tagGroup",
                offset = 0,
                size = 4,
                type = "int",
                what = "field"
              }, {
                address = "0x4",
                count = 4,
                elementSize = 1,
                elementType = "char",
                is = "ptr",
                name = "path",
                offset = 4,
                size = 4,
                what = "field"
              }, {
                address = "0x8",
                is = "int",
                name = "pathSize",
                offset = 8,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "field"
              }, {
                address = "0xc",
                fields = { {
                    address = "0x0",
                    is = "int",
                    name = "value",
                    offset = 0,
                    size = 4,
                    type = "dword",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x0",
                    is = "int",
                    name = "index",
                    offset = 0,
                    size = 2,
                    type = "word",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x2",
                    is = "int",
                    name = "id",
                    offset = 2,
                    size = 2,
                    type = "word",
                    unsigned = true,
                    what = "field"
                  } },
                is = "union",
                metaName = "TableResourceHandle",
                name = "tagHandle",
                offset = 12,
                size = 4,
                type = "TableResourceHandle",
                what = "field"
              } },
            is = "struct",
            metaName = "TagReference",
            name = "physics",
            offset = 128,
            size = 16,
            type = "TagReference",
            what = "field"
          }, {
            address = "0x90",
            fields = { {
                address = "0x0",
                is = "int",
                metaName = "TagGroup",
                name = "tagGroup",
                offset = 0,
                size = 4,
                type = "int",
                what = "field"
              }, {
                address = "0x4",
                count = 4,
                elementSize = 1,
                elementType = "char",
                is = "ptr",
                name = "path",
                offset = 4,
                size = 4,
                what = "field"
              }, {
                address = "0x8",
                is = "int",
                name = "pathSize",
                offset = 8,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "field"
              }, {
                address = "0xc",
                fields = { {
                    address = "0x0",
                    is = "int",
                    name = "value",
                    offset = 0,
                    size = 4,
                    type = "dword",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x0",
                    is = "int",
                    name = "index",
                    offset = 0,
                    size = 2,
                    type = "word",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x2",
                    is = "int",
                    name = "id",
                    offset = 2,
                    size = 2,
                    type = "word",
                    unsigned = true,
                    what = "field"
                  } },
                is = "union",
                metaName = "TableResourceHandle",
                name = "tagHandle",
                offset = 12,
                size = 4,
                type = "TableResourceHandle",
                what = "field"
              } },
            is = "struct",
            metaName = "TagReference",
            name = "modifierShader",
            offset = 144,
            size = 16,
            type = "TagReference",
            what = "field"
          }, {
            address = "0xa0",
            fields = { {
                address = "0x0",
                is = "int",
                metaName = "TagGroup",
                name = "tagGroup",
                offset = 0,
                size = 4,
                type = "int",
                what = "field"
              }, {
                address = "0x4",
                count = 4,
                elementSize = 1,
                elementType = "char",
                is = "ptr",
                name = "path",
                offset = 4,
                size = 4,
                what = "field"
              }, {
                address = "0x8",
                is = "int",
                name = "pathSize",
                offset = 8,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "field"
              }, {
                address = "0xc",
                fields = { {
                    address = "0x0",
                    is = "int",
                    name = "value",
                    offset = 0,
                    size = 4,
                    type = "dword",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x0",
                    is = "int",
                    name = "index",
                    offset = 0,
                    size = 2,
                    type = "word",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x2",
                    is = "int",
                    name = "id",
                    offset = 2,
                    size = 2,
                    type = "word",
                    unsigned = true,
                    what = "field"
                  } },
                is = "union",
                metaName = "TableResourceHandle",
                name = "tagHandle",
                offset = 12,
                size = 4,
                type = "TableResourceHandle",
                what = "field"
              } },
            is = "struct",
            metaName = "TagReference",
            name = "creationEffect",
            offset = 160,
            size = 16,
            type = "TagReference",
            what = "field"
          }, {
            address = "0xb0",
            count = 84,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad5430",
            offset = 176,
            size = 84,
            what = "field"
          }, {
            address = "0x104",
            is = "float",
            name = "renderBoundingRadius",
            offset = 260,
            size = 4,
            type = "float",
            what = "field"
          }, {
            address = "0x108",
            is = "int",
            metaName = "ObjectFunctionIn",
            name = "aIn",
            offset = 264,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0x10a",
            is = "int",
            metaName = "ObjectFunctionIn",
            name = "bIn",
            offset = 266,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0x10c",
            is = "int",
            metaName = "ObjectFunctionIn",
            name = "cIn",
            offset = 268,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0x10e",
            is = "int",
            metaName = "ObjectFunctionIn",
            name = "dIn",
            offset = 270,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0x110",
            count = 44,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad5595",
            offset = 272,
            size = 44,
            what = "field"
          }, {
            address = "0x13c",
            is = "int",
            name = "hudTextMessageIndex",
            offset = 316,
            size = 2,
            type = "word",
            unsigned = true,
            what = "field"
          }, {
            address = "0x13e",
            is = "int",
            name = "forcedShaderPermutationIndex",
            offset = 318,
            size = 2,
            type = "word",
            unsigned = true,
            what = "field"
          }, {
            address = "0x140",
            fields = { {
                address = "0x0",
                is = "int",
                name = "count",
                offset = 0,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "field"
              }, {
                address = "0x4",
                count = 0,
                elementSize = 72,
                fields = { {
                    address = "0x0",
                    fields = { {
                        address = "0x0",
                        is = "int",
                        metaName = "TagGroup",
                        name = "tagGroup",
                        offset = 0,
                        size = 4,
                        type = "int",
                        what = "field"
                      }, {
                        address = "0x4",
                        count = 4,
                        elementSize = 1,
                        elementType = "char",
                        is = "ptr",
                        name = "path",
                        offset = 4,
                        size = 4,
                        what = "field"
                      }, {
                        address = "0x8",
                        is = "int",
                        name = "pathSize",
                        offset = 8,
                        size = 4,
                        type = "dword",
                        unsigned = true,
                        what = "field"
                      }, {
                        address = "0xc",
                        fields = { {
                            address = "0x0",
                            is = "int",
                            name = "value",
                            offset = 0,
                            size = 4,
                            type = "dword",
                            unsigned = true,
                            what = "field"
                          }, {
                            address = "0x0",
                            is = "int",
                            name = "index",
                            offset = 0,
                            size = 2,
                            type = "word",
                            unsigned = true,
                            what = "field"
                          }, {
                            address = "0x2",
                            is = "int",
                            name = "id",
                            offset = 2,
                            size = 2,
                            type = "word",
                            unsigned = true,
                            what = "field"
                          } },
                        is = "union",
                        metaName = "TableResourceHandle",
                        name = "tagHandle",
                        offset = 12,
                        size = 4,
                        type = "TableResourceHandle",
                        what = "field"
                      } },
                    is = "struct",
                    metaName = "TagReference",
                    name = "type",
                    offset = 0,
                    size = 16,
                    type = "TagReference",
                    what = "field"
                  }, {
                    address = "0x10",
                    fields = { {
                        address = "0x0",
                        count = 32,
                        elementSize = 1,
                        elementType = "char",
                        is = "array",
                        name = "string",
                        offset = 0,
                        size = 32,
                        what = "field"
                      } },
                    is = "struct",
                    metaName = "String32",
                    name = "marker",
                    offset = 16,
                    size = 32,
                    type = "String32",
                    what = "field"
                  }, {
                    address = "0x30",
                    is = "int",
                    metaName = "FunctionOut",
                    name = "primaryScale",
                    offset = 48,
                    size = 2,
                    type = "short",
                    what = "field"
                  }, {
                    address = "0x32",
                    is = "int",
                    metaName = "FunctionOut",
                    name = "secondaryScale",
                    offset = 50,
                    size = 2,
                    type = "short",
                    what = "field"
                  }, {
                    address = "0x34",
                    is = "int",
                    metaName = "FunctionNameNullable",
                    name = "changeColor",
                    offset = 52,
                    size = 2,
                    type = "short",
                    what = "field"
                  }, {
                    address = "0x36",
                    count = 2,
                    elementSize = 1,
                    elementType = "char",
                    is = "array",
                    name = "pad3396",
                    offset = 54,
                    size = 2,
                    what = "field"
                  }, {
                    address = "0x38",
                    count = 16,
                    elementSize = 1,
                    elementType = "char",
                    is = "array",
                    name = "pad3418",
                    offset = 56,
                    size = 16,
                    what = "field"
                  } },
                is = "ptr",
                name = "elements",
                offset = 4,
                size = 4,
                what = "field"
              }, {
                address = "0x8",
                count = 0,
                elementSize = 20,
                fields = { {
                    address = "0x0",
                    count = 4,
                    elementSize = 1,
                    elementType = "char",
                    is = "ptr",
                    name = "name",
                    offset = 0,
                    size = 4,
                    what = "field"
                  }, {
                    address = "0x4",
                    is = "int",
                    name = "maximum",
                    offset = 4,
                    size = 4,
                    type = "int",
                    what = "field"
                  }, {
                    address = "0x8",
                    count = 4,
                    elementSize = 1,
                    elementType = "char",
                    is = "array",
                    name = "padding",
                    offset = 8,
                    size = 4,
                    what = "field"
                  }, {
                    address = "0xc",
                    is = "int",
                    name = "elementsSize",
                    offset = 12,
                    size = 4,
                    type = "int",
                    what = "field"
                  }, {
                    address = "0x10",
                    count = 0,
                    elementSize = "none",
                    elementType = "void",
                    is = "ptr",
                    name = "fields",
                    offset = 16,
                    size = 4,
                    what = "field"
                  } },
                is = "ptr",
                name = "definition",
                offset = 8,
                size = 4,
                what = "field"
              } },
            is = "struct",
            name = "attachments",
            offset = 320,
            size = 12,
            what = "field"
          }, {
            address = "0x14c",
            fields = { {
                address = "0x0",
                is = "int",
                name = "count",
                offset = 0,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "field"
              }, {
                address = "0x4",
                count = 0,
                elementSize = 32,
                fields = { {
                    address = "0x0",
                    fields = { {
                        address = "0x0",
                        is = "int",
                        metaName = "TagGroup",
                        name = "tagGroup",
                        offset = 0,
                        size = 4,
                        type = "int",
                        what = "field"
                      }, {
                        address = "0x4",
                        count = 4,
                        elementSize = 1,
                        elementType = "char",
                        is = "ptr",
                        name = "path",
                        offset = 4,
                        size = 4,
                        what = "field"
                      }, {
                        address = "0x8",
                        is = "int",
                        name = "pathSize",
                        offset = 8,
                        size = 4,
                        type = "dword",
                        unsigned = true,
                        what = "field"
                      }, {
                        address = "0xc",
                        fields = { {
                            address = "0x0",
                            is = "int",
                            name = "value",
                            offset = 0,
                            size = 4,
                            type = "dword",
                            unsigned = true,
                            what = "field"
                          }, {
                            address = "0x0",
                            is = "int",
                            name = "index",
                            offset = 0,
                            size = 2,
                            type = "word",
                            unsigned = true,
                            what = "field"
                          }, {
                            address = "0x2",
                            is = "int",
                            name = "id",
                            offset = 2,
                            size = 2,
                            type = "word",
                            unsigned = true,
                            what = "field"
                          } },
                        is = "union",
                        metaName = "TableResourceHandle",
                        name = "tagHandle",
                        offset = 12,
                        size = 4,
                        type = "TableResourceHandle",
                        what = "field"
                      } },
                    is = "struct",
                    metaName = "TagReference",
                    name = "reference",
                    offset = 0,
                    size = 16,
                    type = "TagReference",
                    what = "field"
                  }, {
                    address = "0x10",
                    count = 16,
                    elementSize = 1,
                    elementType = "char",
                    is = "array",
                    name = "pad3569",
                    offset = 16,
                    size = 16,
                    what = "field"
                  } },
                is = "ptr",
                name = "elements",
                offset = 4,
                size = 4,
                what = "field"
              }, {
                address = "0x8",
                count = 0,
                elementSize = 20,
                fields = { {
                    address = "0x0",
                    count = 4,
                    elementSize = 1,
                    elementType = "char",
                    is = "ptr",
                    name = "name",
                    offset = 0,
                    size = 4,
                    what = "field"
                  }, {
                    address = "0x4",
                    is = "int",
                    name = "maximum",
                    offset = 4,
                    size = 4,
                    type = "int",
                    what = "field"
                  }, {
                    address = "0x8",
                    count = 4,
                    elementSize = 1,
                    elementType = "char",
                    is = "array",
                    name = "padding",
                    offset = 8,
                    size = 4,
                    what = "field"
                  }, {
                    address = "0xc",
                    is = "int",
                    name = "elementsSize",
                    offset = 12,
                    size = 4,
                    type = "int",
                    what = "field"
                  }, {
                    address = "0x10",
                    count = 0,
                    elementSize = "none",
                    elementType = "void",
                    is = "ptr",
                    name = "fields",
                    offset = 16,
                    size = 4,
                    what = "field"
                  } },
                is = "ptr",
                name = "definition",
                offset = 8,
                size = 4,
                what = "field"
              } },
            is = "struct",
            name = "widgets",
            offset = 332,
            size = 12,
            what = "field"
          }, {
            address = "0x158",
            fields = { {
                address = "0x0",
                is = "int",
                name = "count",
                offset = 0,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "field"
              }, {
                address = "0x4",
                count = 0,
                elementSize = 360,
                fields = { {
                    address = "0x0",
                    fields = { {
                        address = "0x0",
                        is = "int",
                        name = "invert",
                        offset = 0,
                        size = 4,
                        type = "dword",
                        unsigned = true,
                        what = "bitfield"
                      }, {
                        address = "0x0",
                        is = "int",
                        name = "additive",
                        offset = 1,
                        size = 4,
                        type = "dword",
                        unsigned = true,
                        what = "bitfield"
                      }, {
                        address = "0x0",
                        is = "int",
                        name = "alwaysActive",
                        offset = 2,
                        size = 4,
                        type = "dword",
                        unsigned = true,
                        what = "bitfield"
                      } },
                    is = "struct",
                    metaName = "ObjectFunctionFlags",
                    name = "flags",
                    offset = 0,
                    size = 4,
                    type = "ObjectFunctionFlags",
                    what = "field"
                  }, {
                    address = "0x4",
                    is = "float",
                    name = "period",
                    offset = 4,
                    size = 4,
                    type = "float",
                    what = "field"
                  }, {
                    address = "0x8",
                    is = "int",
                    metaName = "FunctionScaleBy",
                    name = "scalePeriodBy",
                    offset = 8,
                    size = 2,
                    type = "short",
                    what = "field"
                  }, {
                    address = "0xa",
                    is = "int",
                    metaName = "WaveFunction",
                    name = "function",
                    offset = 10,
                    size = 2,
                    type = "short",
                    what = "field"
                  }, {
                    address = "0xc",
                    is = "int",
                    metaName = "FunctionScaleBy",
                    name = "scaleFunctionBy",
                    offset = 12,
                    size = 2,
                    type = "short",
                    what = "field"
                  }, {
                    address = "0xe",
                    is = "int",
                    metaName = "WaveFunction",
                    name = "wobbleFunction",
                    offset = 14,
                    size = 2,
                    type = "short",
                    what = "field"
                  }, {
                    address = "0x10",
                    is = "float",
                    name = "wobblePeriod",
                    offset = 16,
                    size = 4,
                    type = "float",
                    what = "field"
                  }, {
                    address = "0x14",
                    is = "float",
                    name = "wobbleMagnitude",
                    offset = 20,
                    size = 4,
                    type = "float",
                    what = "field"
                  }, {
                    address = "0x18",
                    is = "float",
                    name = "squareWaveThreshold",
                    offset = 24,
                    size = 4,
                    type = "float",
                    what = "field"
                  }, {
                    address = "0x1c",
                    is = "int",
                    name = "stepCount",
                    offset = 28,
                    size = 2,
                    type = "short",
                    what = "field"
                  }, {
                    address = "0x1e",
                    is = "int",
                    metaName = "FunctionType",
                    name = "mapTo",
                    offset = 30,
                    size = 2,
                    type = "short",
                    what = "field"
                  }, {
                    address = "0x20",
                    is = "int",
                    name = "sawtoothCount",
                    offset = 32,
                    size = 2,
                    type = "short",
                    what = "field"
                  }, {
                    address = "0x22",
                    is = "int",
                    metaName = "FunctionScaleBy",
                    name = "add",
                    offset = 34,
                    size = 2,
                    type = "short",
                    what = "field"
                  }, {
                    address = "0x24",
                    is = "int",
                    metaName = "FunctionScaleBy",
                    name = "scaleResultBy",
                    offset = 36,
                    size = 2,
                    type = "short",
                    what = "field"
                  }, {
                    address = "0x26",
                    is = "int",
                    metaName = "FunctionBoundsMode",
                    name = "boundsMode",
                    offset = 38,
                    size = 2,
                    type = "short",
                    what = "field"
                  }, {
                    address = "0x28",
                    count = 2,
                    elementSize = 4,
                    elementType = "float",
                    is = "array",
                    name = "bounds",
                    offset = 40,
                    size = 8,
                    what = "field"
                  }, {
                    address = "0x30",
                    count = 4,
                    elementSize = 1,
                    elementType = "char",
                    is = "array",
                    name = "pad4154",
                    offset = 48,
                    size = 4,
                    what = "field"
                  }, {
                    address = "0x34",
                    count = 2,
                    elementSize = 1,
                    elementType = "char",
                    is = "array",
                    name = "pad4176",
                    offset = 52,
                    size = 2,
                    what = "field"
                  }, {
                    address = "0x36",
                    is = "int",
                    name = "turnOffWith",
                    offset = 54,
                    size = 2,
                    type = "short",
                    what = "field"
                  }, {
                    address = "0x38",
                    is = "float",
                    name = "scaleBy",
                    offset = 56,
                    size = 4,
                    type = "float",
                    what = "field"
                  }, {
                    address = "0x3c",
                    count = 252,
                    elementSize = 1,
                    elementType = "char",
                    is = "array",
                    name = "pad4245",
                    offset = 60,
                    size = 252,
                    what = "field"
                  }, {
                    address = "0x138",
                    is = "float",
                    name = "inverseBounds",
                    offset = 312,
                    size = 4,
                    type = "float",
                    what = "field"
                  }, {
                    address = "0x13c",
                    is = "float",
                    name = "inverseSawtooth",
                    offset = 316,
                    size = 4,
                    type = "float",
                    what = "field"
                  }, {
                    address = "0x140",
                    is = "float",
                    name = "inverseStep",
                    offset = 320,
                    size = 4,
                    type = "float",
                    what = "field"
                  }, {
                    address = "0x144",
                    is = "float",
                    name = "inversePeriod",
                    offset = 324,
                    size = 4,
                    type = "float",
                    what = "field"
                  }, {
                    address = "0x148",
                    fields = { {
                        address = "0x0",
                        count = 32,
                        elementSize = 1,
                        elementType = "char",
                        is = "array",
                        name = "string",
                        offset = 0,
                        size = 32,
                        what = "field"
                      } },
                    is = "struct",
                    metaName = "String32",
                    name = "usage",
                    offset = 328,
                    size = 32,
                    type = "String32",
                    what = "field"
                  } },
                is = "ptr",
                name = "elements",
                offset = 4,
                size = 4,
                what = "field"
              }, {
                address = "0x8",
                count = 0,
                elementSize = 20,
                fields = { {
                    address = "0x0",
                    count = 4,
                    elementSize = 1,
                    elementType = "char",
                    is = "ptr",
                    name = "name",
                    offset = 0,
                    size = 4,
                    what = "field"
                  }, {
                    address = "0x4",
                    is = "int",
                    name = "maximum",
                    offset = 4,
                    size = 4,
                    type = "int",
                    what = "field"
                  }, {
                    address = "0x8",
                    count = 4,
                    elementSize = 1,
                    elementType = "char",
                    is = "array",
                    name = "padding",
                    offset = 8,
                    size = 4,
                    what = "field"
                  }, {
                    address = "0xc",
                    is = "int",
                    name = "elementsSize",
                    offset = 12,
                    size = 4,
                    type = "int",
                    what = "field"
                  }, {
                    address = "0x10",
                    count = 0,
                    elementSize = "none",
                    elementType = "void",
                    is = "ptr",
                    name = "fields",
                    offset = 16,
                    size = 4,
                    what = "field"
                  } },
                is = "ptr",
                name = "definition",
                offset = 8,
                size = 4,
                what = "field"
              } },
            is = "struct",
            name = "functions",
            offset = 344,
            size = 12,
            what = "field"
          }, {
            address = "0x164",
            fields = { {
                address = "0x0",
                is = "int",
                name = "count",
                offset = 0,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "field"
              }, {
                address = "0x4",
                count = 0,
                elementSize = 44,
                fields = { {
                    address = "0x0",
                    is = "int",
                    metaName = "FunctionScaleBy",
                    name = "darkenBy",
                    offset = 0,
                    size = 2,
                    type = "short",
                    what = "field"
                  }, {
                    address = "0x2",
                    is = "int",
                    metaName = "FunctionScaleBy",
                    name = "scaleBy",
                    offset = 2,
                    size = 2,
                    type = "short",
                    what = "field"
                  }, {
                    address = "0x4",
                    fields = { {
                        address = "0x0",
                        is = "int",
                        name = "blendInHsv",
                        offset = 0,
                        size = 4,
                        type = "dword",
                        unsigned = true,
                        what = "bitfield"
                      }, {
                        address = "0x0",
                        is = "int",
                        name = "moreColors",
                        offset = 1,
                        size = 4,
                        type = "dword",
                        unsigned = true,
                        what = "bitfield"
                      } },
                    is = "struct",
                    metaName = "ColorInterpolationFlags",
                    name = "flags",
                    offset = 4,
                    size = 4,
                    type = "ColorInterpolationFlags",
                    what = "field"
                  }, {
                    address = "0x8",
                    count = 2,
                    elementSize = 12,
                    fields = { {
                        address = "0x0",
                        is = "float",
                        name = "r",
                        offset = 0,
                        size = 4,
                        type = "float",
                        what = "field"
                      }, {
                        address = "0x4",
                        is = "float",
                        name = "g",
                        offset = 4,
                        size = 4,
                        type = "float",
                        what = "field"
                      }, {
                        address = "0x8",
                        is = "float",
                        name = "b",
                        offset = 8,
                        size = 4,
                        type = "float",
                        what = "field"
                      } },
                    is = "array",
                    name = "color",
                    offset = 8,
                    size = 24,
                    what = "field"
                  }, {
                    address = "0x20",
                    fields = { {
                        address = "0x0",
                        is = "int",
                        name = "count",
                        offset = 0,
                        size = 4,
                        type = "dword",
                        unsigned = true,
                        what = "field"
                      }, {
                        address = "0x4",
                        count = 0,
                        elementSize = 28,
                        fields = { {
                            address = "0x0",
                            is = "float",
                            name = "weight",
                            offset = 0,
                            size = 4,
                            type = "float",
                            what = "field"
                          }, {
                            address = "0x4",
                            count = 2,
                            elementSize = 12,
                            fields = { {
                                address = "0x0",
                                is = "float",
                                name = "r",
                                offset = 0,
                                size = 4,
                                type = "float",
                                what = "field"
                              }, {
                                address = "0x4",
                                is = "float",
                                name = "g",
                                offset = 4,
                                size = 4,
                                type = "float",
                                what = "field"
                              }, {
                                address = "0x8",
                                is = "float",
                                name = "b",
                                offset = 8,
                                size = 4,
                                type = "float",
                                what = "field"
                              } },
                            is = "array",
                            name = "color",
                            offset = 4,
                            size = 24,
                            what = "field"
                          } },
                        is = "ptr",
                        name = "elements",
                        offset = 4,
                        size = 4,
                        what = "field"
                      }, {
                        address = "0x8",
                        count = 0,
                        elementSize = 20,
                        fields = { {
                            address = "0x0",
                            count = 4,
                            elementSize = 1,
                            elementType = "char",
                            is = "ptr",
                            name = "name",
                            offset = 0,
                            size = 4,
                            what = "field"
                          }, {
                            address = "0x4",
                            is = "int",
                            name = "maximum",
                            offset = 4,
                            size = 4,
                            type = "int",
                            what = "field"
                          }, {
                            address = "0x8",
                            count = 4,
                            elementSize = 1,
                            elementType = "char",
                            is = "array",
                            name = "padding",
                            offset = 8,
                            size = 4,
                            what = "field"
                          }, {
                            address = "0xc",
                            is = "int",
                            name = "elementsSize",
                            offset = 12,
                            size = 4,
                            type = "int",
                            what = "field"
                          }, {
                            address = "0x10",
                            count = 0,
                            elementSize = "none",
                            elementType = "void",
                            is = "ptr",
                            name = "fields",
                            offset = 16,
                            size = 4,
                            what = "field"
                          } },
                        is = "ptr",
                        name = "definition",
                        offset = 8,
                        size = 4,
                        what = "field"
                      } },
                    is = "struct",
                    name = "permutations",
                    offset = 32,
                    size = 12,
                    what = "field"
                  } },
                is = "ptr",
                name = "elements",
                offset = 4,
                size = 4,
                what = "field"
              }, {
                address = "0x8",
                count = 0,
                elementSize = 20,
                fields = { {
                    address = "0x0",
                    count = 4,
                    elementSize = 1,
                    elementType = "char",
                    is = "ptr",
                    name = "name",
                    offset = 0,
                    size = 4,
                    what = "field"
                  }, {
                    address = "0x4",
                    is = "int",
                    name = "maximum",
                    offset = 4,
                    size = 4,
                    type = "int",
                    what = "field"
                  }, {
                    address = "0x8",
                    count = 4,
                    elementSize = 1,
                    elementType = "char",
                    is = "array",
                    name = "padding",
                    offset = 8,
                    size = 4,
                    what = "field"
                  }, {
                    address = "0xc",
                    is = "int",
                    name = "elementsSize",
                    offset = 12,
                    size = 4,
                    type = "int",
                    what = "field"
                  }, {
                    address = "0x10",
                    count = 0,
                    elementSize = "none",
                    elementType = "void",
                    is = "ptr",
                    name = "fields",
                    offset = 16,
                    size = 4,
                    what = "field"
                  } },
                is = "ptr",
                name = "definition",
                offset = 8,
                size = 4,
                what = "field"
              } },
            is = "struct",
            name = "changeColors",
            offset = 356,
            size = 12,
            what = "field"
          }, {
            address = "0x170",
            fields = { {
                address = "0x0",
                is = "int",
                name = "count",
                offset = 0,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "field"
              }, {
                address = "0x4",
                count = 0,
                elementSize = 8,
                fields = { {
                    address = "0x0",
                    is = "int",
                    metaName = "PredictedResourceType",
                    name = "type",
                    offset = 0,
                    size = 2,
                    type = "short",
                    what = "field"
                  }, {
                    address = "0x2",
                    is = "int",
                    name = "resourceIndex",
                    offset = 2,
                    size = 2,
                    type = "word",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x4",
                    fields = { {
                        address = "0x0",
                        is = "int",
                        name = "value",
                        offset = 0,
                        size = 4,
                        type = "dword",
                        unsigned = true,
                        what = "field"
                      }, {
                        address = "0x0",
                        is = "int",
                        name = "index",
                        offset = 0,
                        size = 2,
                        type = "word",
                        unsigned = true,
                        what = "field"
                      }, {
                        address = "0x2",
                        is = "int",
                        name = "id",
                        offset = 2,
                        size = 2,
                        type = "word",
                        unsigned = true,
                        what = "field"
                      } },
                    is = "union",
                    metaName = "TableResourceHandle",
                    name = "tag",
                    offset = 4,
                    size = 4,
                    type = "TableResourceHandle",
                    what = "field"
                  } },
                is = "ptr",
                name = "elements",
                offset = 4,
                size = 4,
                what = "field"
              }, {
                address = "0x8",
                count = 0,
                elementSize = 20,
                fields = { {
                    address = "0x0",
                    count = 4,
                    elementSize = 1,
                    elementType = "char",
                    is = "ptr",
                    name = "name",
                    offset = 0,
                    size = 4,
                    what = "field"
                  }, {
                    address = "0x4",
                    is = "int",
                    name = "maximum",
                    offset = 4,
                    size = 4,
                    type = "int",
                    what = "field"
                  }, {
                    address = "0x8",
                    count = 4,
                    elementSize = 1,
                    elementType = "char",
                    is = "array",
                    name = "padding",
                    offset = 8,
                    size = 4,
                    what = "field"
                  }, {
                    address = "0xc",
                    is = "int",
                    name = "elementsSize",
                    offset = 12,
                    size = 4,
                    type = "int",
                    what = "field"
                  }, {
                    address = "0x10",
                    count = 0,
                    elementSize = "none",
                    elementType = "void",
                    is = "ptr",
                    name = "fields",
                    offset = 16,
                    size = 4,
                    what = "field"
                  } },
                is = "ptr",
                name = "definition",
                offset = 8,
                size = 4,
                what = "field"
              } },
            is = "struct",
            name = "predictedResources",
            offset = 368,
            size = 12,
            what = "field"
          } },
        is = "struct",
        metaName = "Object",
        name = "base",
        offset = 0,
        size = 380,
        type = "Object",
        what = "field"
      }, {
        address = "0x17c",
        fields = { {
            address = "0x0",
            is = "int",
            name = "alwaysMaintainsZUp",
            offset = 0,
            size = 4,
            type = "dword",
            unsigned = true,
            what = "bitfield"
          }, {
            address = "0x0",
            is = "int",
            name = "destroyedByExplosions",
            offset = 1,
            size = 4,
            type = "dword",
            unsigned = true,
            what = "bitfield"
          }, {
            address = "0x0",
            is = "int",
            name = "unaffectedByGravity",
            offset = 2,
            size = 4,
            type = "dword",
            unsigned = true,
            what = "bitfield"
          } },
        is = "struct",
        metaName = "ItemFlags",
        name = "flags",
        offset = 380,
        size = 4,
        type = "ItemFlags",
        what = "field"
      }, {
        address = "0x180",
        is = "int",
        name = "pickupTextIndex",
        offset = 384,
        size = 2,
        type = "word",
        unsigned = true,
        what = "field"
      }, {
        address = "0x182",
        is = "int",
        name = "sortOrder",
        offset = 386,
        size = 2,
        type = "short",
        what = "field"
      }, {
        address = "0x184",
        is = "float",
        name = "scale",
        offset = 388,
        size = 4,
        type = "float",
        what = "field"
      }, {
        address = "0x188",
        is = "int",
        name = "hudMessageValueScale",
        offset = 392,
        size = 2,
        type = "short",
        what = "field"
      }, {
        address = "0x18a",
        count = 2,
        elementSize = 1,
        elementType = "char",
        is = "array",
        name = "pad861",
        offset = 394,
        size = 2,
        what = "field"
      }, {
        address = "0x18c",
        count = 16,
        elementSize = 1,
        elementType = "char",
        is = "array",
        name = "pad882",
        offset = 396,
        size = 16,
        what = "field"
      }, {
        address = "0x19c",
        is = "int",
        metaName = "ItemFunctionIn",
        name = "aIn",
        offset = 412,
        size = 2,
        type = "short",
        what = "field"
      }, {
        address = "0x19e",
        is = "int",
        metaName = "ItemFunctionIn",
        name = "bIn",
        offset = 414,
        size = 2,
        type = "short",
        what = "field"
      }, {
        address = "0x1a0",
        is = "int",
        metaName = "ItemFunctionIn",
        name = "cIn",
        offset = 416,
        size = 2,
        type = "short",
        what = "field"
      }, {
        address = "0x1a2",
        is = "int",
        metaName = "ItemFunctionIn",
        name = "dIn",
        offset = 418,
        size = 2,
        type = "short",
        what = "field"
      }, {
        address = "0x1a4",
        count = 164,
        elementSize = 1,
        elementType = "char",
        is = "array",
        name = "pad1004",
        offset = 420,
        size = 164,
        what = "field"
      }, {
        address = "0x248",
        fields = { {
            address = "0x0",
            is = "int",
            metaName = "TagGroup",
            name = "tagGroup",
            offset = 0,
            size = 4,
            type = "int",
            what = "field"
          }, {
            address = "0x4",
            count = 4,
            elementSize = 1,
            elementType = "char",
            is = "ptr",
            name = "path",
            offset = 4,
            size = 4,
            what = "field"
          }, {
            address = "0x8",
            is = "int",
            name = "pathSize",
            offset = 8,
            size = 4,
            type = "dword",
            unsigned = true,
            what = "field"
          }, {
            address = "0xc",
            fields = { {
                address = "0x0",
                is = "int",
                name = "value",
                offset = 0,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "field"
              }, {
                address = "0x0",
                is = "int",
                name = "index",
                offset = 0,
                size = 2,
                type = "word",
                unsigned = true,
                what = "field"
              }, {
                address = "0x2",
                is = "int",
                name = "id",
                offset = 2,
                size = 2,
                type = "word",
                unsigned = true,
                what = "field"
              } },
            is = "union",
            metaName = "TableResourceHandle",
            name = "tagHandle",
            offset = 12,
            size = 4,
            type = "TableResourceHandle",
            what = "field"
          } },
        is = "struct",
        metaName = "TagReference",
        name = "materialEffects",
        offset = 584,
        size = 16,
        type = "TagReference",
        what = "field"
      }, {
        address = "0x258",
        fields = { {
            address = "0x0",
            is = "int",
            metaName = "TagGroup",
            name = "tagGroup",
            offset = 0,
            size = 4,
            type = "int",
            what = "field"
          }, {
            address = "0x4",
            count = 4,
            elementSize = 1,
            elementType = "char",
            is = "ptr",
            name = "path",
            offset = 4,
            size = 4,
            what = "field"
          }, {
            address = "0x8",
            is = "int",
            name = "pathSize",
            offset = 8,
            size = 4,
            type = "dword",
            unsigned = true,
            what = "field"
          }, {
            address = "0xc",
            fields = { {
                address = "0x0",
                is = "int",
                name = "value",
                offset = 0,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "field"
              }, {
                address = "0x0",
                is = "int",
                name = "index",
                offset = 0,
                size = 2,
                type = "word",
                unsigned = true,
                what = "field"
              }, {
                address = "0x2",
                is = "int",
                name = "id",
                offset = 2,
                size = 2,
                type = "word",
                unsigned = true,
                what = "field"
              } },
            is = "union",
            metaName = "TableResourceHandle",
            name = "tagHandle",
            offset = 12,
            size = 4,
            type = "TableResourceHandle",
            what = "field"
          } },
        is = "struct",
        metaName = "TagReference",
        name = "collisionSound",
        offset = 600,
        size = 16,
        type = "TagReference",
        what = "field"
      }, {
        address = "0x268",
        count = 120,
        elementSize = 1,
        elementType = "char",
        is = "array",
        name = "pad1097",
        offset = 616,
        size = 120,
        what = "field"
      }, {
        address = "0x2e0",
        count = 2,
        elementSize = 4,
        elementType = "float",
        is = "array",
        name = "detonationDelay",
        offset = 736,
        size = 8,
        what = "field"
      }, {
        address = "0x2e8",
        fields = { {
            address = "0x0",
            is = "int",
            metaName = "TagGroup",
            name = "tagGroup",
            offset = 0,
            size = 4,
            type = "int",
            what = "field"
          }, {
            address = "0x4",
            count = 4,
            elementSize = 1,
            elementType = "char",
            is = "ptr",
            name = "path",
            offset = 4,
            size = 4,
            what = "field"
          }, {
            address = "0x8",
            is = "int",
            name = "pathSize",
            offset = 8,
            size = 4,
            type = "dword",
            unsigned = true,
            what = "field"
          }, {
            address = "0xc",
            fields = { {
                address = "0x0",
                is = "int",
                name = "value",
                offset = 0,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "field"
              }, {
                address = "0x0",
                is = "int",
                name = "index",
                offset = 0,
                size = 2,
                type = "word",
                unsigned = true,
                what = "field"
              }, {
                address = "0x2",
                is = "int",
                name = "id",
                offset = 2,
                size = 2,
                type = "word",
                unsigned = true,
                what = "field"
              } },
            is = "union",
            metaName = "TableResourceHandle",
            name = "tagHandle",
            offset = 12,
            size = 4,
            type = "TableResourceHandle",
            what = "field"
          } },
        is = "struct",
        metaName = "TagReference",
        name = "detonatingEffect",
        offset = 744,
        size = 16,
        type = "TagReference",
        what = "field"
      }, {
        address = "0x2f8",
        fields = { {
            address = "0x0",
            is = "int",
            metaName = "TagGroup",
            name = "tagGroup",
            offset = 0,
            size = 4,
            type = "int",
            what = "field"
          }, {
            address = "0x4",
            count = 4,
            elementSize = 1,
            elementType = "char",
            is = "ptr",
            name = "path",
            offset = 4,
            size = 4,
            what = "field"
          }, {
            address = "0x8",
            is = "int",
            name = "pathSize",
            offset = 8,
            size = 4,
            type = "dword",
            unsigned = true,
            what = "field"
          }, {
            address = "0xc",
            fields = { {
                address = "0x0",
                is = "int",
                name = "value",
                offset = 0,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "field"
              }, {
                address = "0x0",
                is = "int",
                name = "index",
                offset = 0,
                size = 2,
                type = "word",
                unsigned = true,
                what = "field"
              }, {
                address = "0x2",
                is = "int",
                name = "id",
                offset = 2,
                size = 2,
                type = "word",
                unsigned = true,
                what = "field"
              } },
            is = "union",
            metaName = "TableResourceHandle",
            name = "tagHandle",
            offset = 12,
            size = 4,
            type = "TableResourceHandle",
            what = "field"
          } },
        is = "struct",
        metaName = "TagReference",
        name = "detonationEffect",
        offset = 760,
        size = 16,
        type = "TagReference",
        what = "field"
      } },
    is = "struct",
    metaName = "Item",
    name = "base",
    offset = 0,
    size = 776,
    type = "Item",
    what = "field"
  }, {
    address = "0x308",
    fields = { {
        address = "0x0",
        is = "int",
        name = "verticalHeatDisplay",
        offset = 0,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x0",
        is = "int",
        name = "mutuallyExclusiveTriggers",
        offset = 1,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x0",
        is = "int",
        name = "attacksAutomaticallyOnBump",
        offset = 2,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x0",
        is = "int",
        name = "mustBeReadied",
        offset = 3,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x0",
        is = "int",
        name = "doesntCountTowardMaximum",
        offset = 4,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x0",
        is = "int",
        name = "aimAssistsOnlyWhenZoomed",
        offset = 5,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x0",
        is = "int",
        name = "preventsGrenadeThrowing",
        offset = 6,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x0",
        is = "int",
        name = "mustBePickedUp",
        offset = 7,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x1",
        is = "int",
        name = "holdsTriggersWhenDropped",
        offset = 8,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x1",
        is = "int",
        name = "preventsMeleeAttack",
        offset = 9,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x1",
        is = "int",
        name = "detonatesWhenDropped",
        offset = 10,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x1",
        is = "int",
        name = "cannotFireAtMaximumAge",
        offset = 11,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x1",
        is = "int",
        name = "secondaryTriggerOverridesGrenades",
        offset = 12,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x1",
        is = "int",
        name = "doesNotDepowerActiveCamoInMultiplayer",
        offset = 13,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x1",
        is = "int",
        name = "enablesIntegratedNightVision",
        offset = 14,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x1",
        is = "int",
        name = "aisUseWeaponMeleeDamage",
        offset = 15,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x2",
        is = "int",
        name = "preventsCrouching",
        offset = 16,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x2",
        is = "int",
        name = "uses3rdPersonCamera",
        offset = 17,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      } },
    is = "struct",
    metaName = "WeaponFlags",
    name = "weaponFlags",
    offset = 776,
    size = 4,
    type = "WeaponFlags",
    what = "field"
  }, {
    address = "0x30c",
    fields = { {
        address = "0x0",
        count = 32,
        elementSize = 1,
        elementType = "char",
        is = "array",
        name = "string",
        offset = 0,
        size = 32,
        what = "field"
      } },
    is = "struct",
    metaName = "String32",
    name = "label",
    offset = 780,
    size = 32,
    type = "String32",
    what = "field"
  }, {
    address = "0x32c",
    is = "int",
    metaName = "WeaponSecondaryTriggerMode",
    name = "secondaryTriggerMode",
    offset = 812,
    size = 2,
    type = "short",
    what = "field"
  }, {
    address = "0x32e",
    is = "int",
    name = "maximumAlternateShotsLoaded",
    offset = 814,
    size = 2,
    type = "short",
    what = "field"
  }, {
    address = "0x330",
    is = "int",
    metaName = "WeaponFunctionIn",
    name = "weaponAIn",
    offset = 816,
    size = 2,
    type = "short",
    what = "field"
  }, {
    address = "0x332",
    is = "int",
    metaName = "WeaponFunctionIn",
    name = "weaponBIn",
    offset = 818,
    size = 2,
    type = "short",
    what = "field"
  }, {
    address = "0x334",
    is = "int",
    metaName = "WeaponFunctionIn",
    name = "weaponCIn",
    offset = 820,
    size = 2,
    type = "short",
    what = "field"
  }, {
    address = "0x336",
    is = "int",
    metaName = "WeaponFunctionIn",
    name = "weaponDIn",
    offset = 822,
    size = 2,
    type = "short",
    what = "field"
  }, {
    address = "0x338",
    is = "float",
    name = "readyTime",
    offset = 824,
    size = 4,
    type = "float",
    what = "field"
  }, {
    address = "0x33c",
    fields = { {
        address = "0x0",
        is = "int",
        metaName = "TagGroup",
        name = "tagGroup",
        offset = 0,
        size = 4,
        type = "int",
        what = "field"
      }, {
        address = "0x4",
        count = 4,
        elementSize = 1,
        elementType = "char",
        is = "ptr",
        name = "path",
        offset = 4,
        size = 4,
        what = "field"
      }, {
        address = "0x8",
        is = "int",
        name = "pathSize",
        offset = 8,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "field"
      }, {
        address = "0xc",
        fields = { {
            address = "0x0",
            is = "int",
            name = "value",
            offset = 0,
            size = 4,
            type = "dword",
            unsigned = true,
            what = "field"
          }, {
            address = "0x0",
            is = "int",
            name = "index",
            offset = 0,
            size = 2,
            type = "word",
            unsigned = true,
            what = "field"
          }, {
            address = "0x2",
            is = "int",
            name = "id",
            offset = 2,
            size = 2,
            type = "word",
            unsigned = true,
            what = "field"
          } },
        is = "union",
        metaName = "TableResourceHandle",
        name = "tagHandle",
        offset = 12,
        size = 4,
        type = "TableResourceHandle",
        what = "field"
      } },
    is = "struct",
    metaName = "TagReference",
    name = "readyEffect",
    offset = 828,
    size = 16,
    type = "TagReference",
    what = "field"
  }, {
    address = "0x34c",
    is = "float",
    name = "heatRecoveryThreshold",
    offset = 844,
    size = 4,
    type = "float",
    what = "field"
  }, {
    address = "0x350",
    is = "float",
    name = "overheatedThreshold",
    offset = 848,
    size = 4,
    type = "float",
    what = "field"
  }, {
    address = "0x354",
    is = "float",
    name = "heatDetonationThreshold",
    offset = 852,
    size = 4,
    type = "float",
    what = "field"
  }, {
    address = "0x358",
    is = "float",
    name = "heatDetonationFraction",
    offset = 856,
    size = 4,
    type = "float",
    what = "field"
  }, {
    address = "0x35c",
    is = "float",
    name = "heatLossRate",
    offset = 860,
    size = 4,
    type = "float",
    what = "field"
  }, {
    address = "0x360",
    is = "float",
    name = "heatIllumination",
    offset = 864,
    size = 4,
    type = "float",
    what = "field"
  }, {
    address = "0x364",
    count = 16,
    elementSize = 1,
    elementType = "char",
    is = "array",
    name = "pad8463",
    offset = 868,
    size = 16,
    what = "field"
  }, {
    address = "0x374",
    fields = { {
        address = "0x0",
        is = "int",
        metaName = "TagGroup",
        name = "tagGroup",
        offset = 0,
        size = 4,
        type = "int",
        what = "field"
      }, {
        address = "0x4",
        count = 4,
        elementSize = 1,
        elementType = "char",
        is = "ptr",
        name = "path",
        offset = 4,
        size = 4,
        what = "field"
      }, {
        address = "0x8",
        is = "int",
        name = "pathSize",
        offset = 8,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "field"
      }, {
        address = "0xc",
        fields = { {
            address = "0x0",
            is = "int",
            name = "value",
            offset = 0,
            size = 4,
            type = "dword",
            unsigned = true,
            what = "field"
          }, {
            address = "0x0",
            is = "int",
            name = "index",
            offset = 0,
            size = 2,
            type = "word",
            unsigned = true,
            what = "field"
          }, {
            address = "0x2",
            is = "int",
            name = "id",
            offset = 2,
            size = 2,
            type = "word",
            unsigned = true,
            what = "field"
          } },
        is = "union",
        metaName = "TableResourceHandle",
        name = "tagHandle",
        offset = 12,
        size = 4,
        type = "TableResourceHandle",
        what = "field"
      } },
    is = "struct",
    metaName = "TagReference",
    name = "overheated",
    offset = 884,
    size = 16,
    type = "TagReference",
    what = "field"
  }, {
    address = "0x384",
    fields = { {
        address = "0x0",
        is = "int",
        metaName = "TagGroup",
        name = "tagGroup",
        offset = 0,
        size = 4,
        type = "int",
        what = "field"
      }, {
        address = "0x4",
        count = 4,
        elementSize = 1,
        elementType = "char",
        is = "ptr",
        name = "path",
        offset = 4,
        size = 4,
        what = "field"
      }, {
        address = "0x8",
        is = "int",
        name = "pathSize",
        offset = 8,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "field"
      }, {
        address = "0xc",
        fields = { {
            address = "0x0",
            is = "int",
            name = "value",
            offset = 0,
            size = 4,
            type = "dword",
            unsigned = true,
            what = "field"
          }, {
            address = "0x0",
            is = "int",
            name = "index",
            offset = 0,
            size = 2,
            type = "word",
            unsigned = true,
            what = "field"
          }, {
            address = "0x2",
            is = "int",
            name = "id",
            offset = 2,
            size = 2,
            type = "word",
            unsigned = true,
            what = "field"
          } },
        is = "union",
        metaName = "TableResourceHandle",
        name = "tagHandle",
        offset = 12,
        size = 4,
        type = "TableResourceHandle",
        what = "field"
      } },
    is = "struct",
    metaName = "TagReference",
    name = "overheatDetonation",
    offset = 900,
    size = 16,
    type = "TagReference",
    what = "field"
  }, {
    address = "0x394",
    fields = { {
        address = "0x0",
        is = "int",
        metaName = "TagGroup",
        name = "tagGroup",
        offset = 0,
        size = 4,
        type = "int",
        what = "field"
      }, {
        address = "0x4",
        count = 4,
        elementSize = 1,
        elementType = "char",
        is = "ptr",
        name = "path",
        offset = 4,
        size = 4,
        what = "field"
      }, {
        address = "0x8",
        is = "int",
        name = "pathSize",
        offset = 8,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "field"
      }, {
        address = "0xc",
        fields = { {
            address = "0x0",
            is = "int",
            name = "value",
            offset = 0,
            size = 4,
            type = "dword",
            unsigned = true,
            what = "field"
          }, {
            address = "0x0",
            is = "int",
            name = "index",
            offset = 0,
            size = 2,
            type = "word",
            unsigned = true,
            what = "field"
          }, {
            address = "0x2",
            is = "int",
            name = "id",
            offset = 2,
            size = 2,
            type = "word",
            unsigned = true,
            what = "field"
          } },
        is = "union",
        metaName = "TableResourceHandle",
        name = "tagHandle",
        offset = 12,
        size = 4,
        type = "TableResourceHandle",
        what = "field"
      } },
    is = "struct",
    metaName = "TagReference",
    name = "playerMeleeDamage",
    offset = 916,
    size = 16,
    type = "TagReference",
    what = "field"
  }, {
    address = "0x3a4",
    fields = { {
        address = "0x0",
        is = "int",
        metaName = "TagGroup",
        name = "tagGroup",
        offset = 0,
        size = 4,
        type = "int",
        what = "field"
      }, {
        address = "0x4",
        count = 4,
        elementSize = 1,
        elementType = "char",
        is = "ptr",
        name = "path",
        offset = 4,
        size = 4,
        what = "field"
      }, {
        address = "0x8",
        is = "int",
        name = "pathSize",
        offset = 8,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "field"
      }, {
        address = "0xc",
        fields = { {
            address = "0x0",
            is = "int",
            name = "value",
            offset = 0,
            size = 4,
            type = "dword",
            unsigned = true,
            what = "field"
          }, {
            address = "0x0",
            is = "int",
            name = "index",
            offset = 0,
            size = 2,
            type = "word",
            unsigned = true,
            what = "field"
          }, {
            address = "0x2",
            is = "int",
            name = "id",
            offset = 2,
            size = 2,
            type = "word",
            unsigned = true,
            what = "field"
          } },
        is = "union",
        metaName = "TableResourceHandle",
        name = "tagHandle",
        offset = 12,
        size = 4,
        type = "TableResourceHandle",
        what = "field"
      } },
    is = "struct",
    metaName = "TagReference",
    name = "playerMeleeResponse",
    offset = 932,
    size = 16,
    type = "TagReference",
    what = "field"
  }, {
    address = "0x3b4",
    count = 8,
    elementSize = 1,
    elementType = "char",
    is = "array",
    name = "pad8631",
    offset = 948,
    size = 8,
    what = "field"
  }, {
    address = "0x3bc",
    fields = { {
        address = "0x0",
        is = "int",
        metaName = "TagGroup",
        name = "tagGroup",
        offset = 0,
        size = 4,
        type = "int",
        what = "field"
      }, {
        address = "0x4",
        count = 4,
        elementSize = 1,
        elementType = "char",
        is = "ptr",
        name = "path",
        offset = 4,
        size = 4,
        what = "field"
      }, {
        address = "0x8",
        is = "int",
        name = "pathSize",
        offset = 8,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "field"
      }, {
        address = "0xc",
        fields = { {
            address = "0x0",
            is = "int",
            name = "value",
            offset = 0,
            size = 4,
            type = "dword",
            unsigned = true,
            what = "field"
          }, {
            address = "0x0",
            is = "int",
            name = "index",
            offset = 0,
            size = 2,
            type = "word",
            unsigned = true,
            what = "field"
          }, {
            address = "0x2",
            is = "int",
            name = "id",
            offset = 2,
            size = 2,
            type = "word",
            unsigned = true,
            what = "field"
          } },
        is = "union",
        metaName = "TableResourceHandle",
        name = "tagHandle",
        offset = 12,
        size = 4,
        type = "TableResourceHandle",
        what = "field"
      } },
    is = "struct",
    metaName = "TagReference",
    name = "actorFiringParameters",
    offset = 956,
    size = 16,
    type = "TagReference",
    what = "field"
  }, {
    address = "0x3cc",
    is = "float",
    name = "nearReticleRange",
    offset = 972,
    size = 4,
    type = "float",
    what = "field"
  }, {
    address = "0x3d0",
    is = "float",
    name = "farReticleRange",
    offset = 976,
    size = 4,
    type = "float",
    what = "field"
  }, {
    address = "0x3d4",
    is = "float",
    name = "intersectionReticleRange",
    offset = 980,
    size = 4,
    type = "float",
    what = "field"
  }, {
    address = "0x3d8",
    count = 2,
    elementSize = 1,
    elementType = "char",
    is = "array",
    name = "pad8792",
    offset = 984,
    size = 2,
    what = "field"
  }, {
    address = "0x3da",
    is = "int",
    name = "zoomLevels",
    offset = 986,
    size = 2,
    type = "word",
    unsigned = true,
    what = "field"
  }, {
    address = "0x3dc",
    count = 2,
    elementSize = 4,
    elementType = "float",
    is = "array",
    name = "zoomMagnificationRange",
    offset = 988,
    size = 8,
    what = "field"
  }, {
    address = "0x3e4",
    is = "float",
    name = "autoaimAngle",
    offset = 996,
    size = 4,
    type = "float",
    what = "field"
  }, {
    address = "0x3e8",
    is = "float",
    name = "autoaimRange",
    offset = 1000,
    size = 4,
    type = "float",
    what = "field"
  }, {
    address = "0x3ec",
    is = "float",
    name = "magnetismAngle",
    offset = 1004,
    size = 4,
    type = "float",
    what = "field"
  }, {
    address = "0x3f0",
    is = "float",
    name = "magnetismRange",
    offset = 1008,
    size = 4,
    type = "float",
    what = "field"
  }, {
    address = "0x3f4",
    is = "float",
    name = "deviationAngle",
    offset = 1012,
    size = 4,
    type = "float",
    what = "field"
  }, {
    address = "0x3f8",
    count = 4,
    elementSize = 1,
    elementType = "char",
    is = "array",
    name = "pad9010",
    offset = 1016,
    size = 4,
    what = "field"
  }, {
    address = "0x3fc",
    is = "int",
    metaName = "WeaponMovementPenalized",
    name = "movementPenalized",
    offset = 1020,
    size = 2,
    type = "short",
    what = "field"
  }, {
    address = "0x3fe",
    count = 2,
    elementSize = 1,
    elementType = "char",
    is = "array",
    name = "pad9080",
    offset = 1022,
    size = 2,
    what = "field"
  }, {
    address = "0x400",
    is = "float",
    name = "forwardMovementPenalty",
    offset = 1024,
    size = 4,
    type = "float",
    what = "field"
  }, {
    address = "0x404",
    is = "float",
    name = "sidewaysMovementPenalty",
    offset = 1028,
    size = 4,
    type = "float",
    what = "field"
  }, {
    address = "0x408",
    count = 4,
    elementSize = 1,
    elementType = "char",
    is = "array",
    name = "pad9175",
    offset = 1032,
    size = 4,
    what = "field"
  }, {
    address = "0x40c",
    is = "float",
    name = "minimumTargetRange",
    offset = 1036,
    size = 4,
    type = "float",
    what = "field"
  }, {
    address = "0x410",
    is = "float",
    name = "lookingTimeModifier",
    offset = 1040,
    size = 4,
    type = "float",
    what = "field"
  }, {
    address = "0x414",
    count = 4,
    elementSize = 1,
    elementType = "char",
    is = "array",
    name = "pad9262",
    offset = 1044,
    size = 4,
    what = "field"
  }, {
    address = "0x418",
    is = "float",
    name = "lightPowerOnTime",
    offset = 1048,
    size = 4,
    type = "float",
    what = "field"
  }, {
    address = "0x41c",
    is = "float",
    name = "lightPowerOffTime",
    offset = 1052,
    size = 4,
    type = "float",
    what = "field"
  }, {
    address = "0x420",
    fields = { {
        address = "0x0",
        is = "int",
        metaName = "TagGroup",
        name = "tagGroup",
        offset = 0,
        size = 4,
        type = "int",
        what = "field"
      }, {
        address = "0x4",
        count = 4,
        elementSize = 1,
        elementType = "char",
        is = "ptr",
        name = "path",
        offset = 4,
        size = 4,
        what = "field"
      }, {
        address = "0x8",
        is = "int",
        name = "pathSize",
        offset = 8,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "field"
      }, {
        address = "0xc",
        fields = { {
            address = "0x0",
            is = "int",
            name = "value",
            offset = 0,
            size = 4,
            type = "dword",
            unsigned = true,
            what = "field"
          }, {
            address = "0x0",
            is = "int",
            name = "index",
            offset = 0,
            size = 2,
            type = "word",
            unsigned = true,
            what = "field"
          }, {
            address = "0x2",
            is = "int",
            name = "id",
            offset = 2,
            size = 2,
            type = "word",
            unsigned = true,
            what = "field"
          } },
        is = "union",
        metaName = "TableResourceHandle",
        name = "tagHandle",
        offset = 12,
        size = 4,
        type = "TableResourceHandle",
        what = "field"
      } },
    is = "struct",
    metaName = "TagReference",
    name = "lightPowerOnEffect",
    offset = 1056,
    size = 16,
    type = "TagReference",
    what = "field"
  }, {
    address = "0x430",
    fields = { {
        address = "0x0",
        is = "int",
        metaName = "TagGroup",
        name = "tagGroup",
        offset = 0,
        size = 4,
        type = "int",
        what = "field"
      }, {
        address = "0x4",
        count = 4,
        elementSize = 1,
        elementType = "char",
        is = "ptr",
        name = "path",
        offset = 4,
        size = 4,
        what = "field"
      }, {
        address = "0x8",
        is = "int",
        name = "pathSize",
        offset = 8,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "field"
      }, {
        address = "0xc",
        fields = { {
            address = "0x0",
            is = "int",
            name = "value",
            offset = 0,
            size = 4,
            type = "dword",
            unsigned = true,
            what = "field"
          }, {
            address = "0x0",
            is = "int",
            name = "index",
            offset = 0,
            size = 2,
            type = "word",
            unsigned = true,
            what = "field"
          }, {
            address = "0x2",
            is = "int",
            name = "id",
            offset = 2,
            size = 2,
            type = "word",
            unsigned = true,
            what = "field"
          } },
        is = "union",
        metaName = "TableResourceHandle",
        name = "tagHandle",
        offset = 12,
        size = 4,
        type = "TableResourceHandle",
        what = "field"
      } },
    is = "struct",
    metaName = "TagReference",
    name = "lightPowerOffEffect",
    offset = 1072,
    size = 16,
    type = "TagReference",
    what = "field"
  }, {
    address = "0x440",
    is = "float",
    name = "ageHeatRecoveryPenalty",
    offset = 1088,
    size = 4,
    type = "float",
    what = "field"
  }, {
    address = "0x444",
    is = "float",
    name = "ageRateOfFirePenalty",
    offset = 1092,
    size = 4,
    type = "float",
    what = "field"
  }, {
    address = "0x448",
    is = "float",
    name = "ageMisfireStart",
    offset = 1096,
    size = 4,
    type = "float",
    what = "field"
  }, {
    address = "0x44c",
    is = "float",
    name = "ageMisfireChance",
    offset = 1100,
    size = 4,
    type = "float",
    what = "field"
  }, {
    address = "0x450",
    count = 12,
    elementSize = 1,
    elementType = "char",
    is = "array",
    name = "pad9560",
    offset = 1104,
    size = 12,
    what = "field"
  }, {
    address = "0x45c",
    fields = { {
        address = "0x0",
        is = "int",
        metaName = "TagGroup",
        name = "tagGroup",
        offset = 0,
        size = 4,
        type = "int",
        what = "field"
      }, {
        address = "0x4",
        count = 4,
        elementSize = 1,
        elementType = "char",
        is = "ptr",
        name = "path",
        offset = 4,
        size = 4,
        what = "field"
      }, {
        address = "0x8",
        is = "int",
        name = "pathSize",
        offset = 8,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "field"
      }, {
        address = "0xc",
        fields = { {
            address = "0x0",
            is = "int",
            name = "value",
            offset = 0,
            size = 4,
            type = "dword",
            unsigned = true,
            what = "field"
          }, {
            address = "0x0",
            is = "int",
            name = "index",
            offset = 0,
            size = 2,
            type = "word",
            unsigned = true,
            what = "field"
          }, {
            address = "0x2",
            is = "int",
            name = "id",
            offset = 2,
            size = 2,
            type = "word",
            unsigned = true,
            what = "field"
          } },
        is = "union",
        metaName = "TableResourceHandle",
        name = "tagHandle",
        offset = 12,
        size = 4,
        type = "TableResourceHandle",
        what = "field"
      } },
    is = "struct",
    metaName = "TagReference",
    name = "firstPersonModel",
    offset = 1116,
    size = 16,
    type = "TagReference",
    what = "field"
  }, {
    address = "0x46c",
    fields = { {
        address = "0x0",
        is = "int",
        metaName = "TagGroup",
        name = "tagGroup",
        offset = 0,
        size = 4,
        type = "int",
        what = "field"
      }, {
        address = "0x4",
        count = 4,
        elementSize = 1,
        elementType = "char",
        is = "ptr",
        name = "path",
        offset = 4,
        size = 4,
        what = "field"
      }, {
        address = "0x8",
        is = "int",
        name = "pathSize",
        offset = 8,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "field"
      }, {
        address = "0xc",
        fields = { {
            address = "0x0",
            is = "int",
            name = "value",
            offset = 0,
            size = 4,
            type = "dword",
            unsigned = true,
            what = "field"
          }, {
            address = "0x0",
            is = "int",
            name = "index",
            offset = 0,
            size = 2,
            type = "word",
            unsigned = true,
            what = "field"
          }, {
            address = "0x2",
            is = "int",
            name = "id",
            offset = 2,
            size = 2,
            type = "word",
            unsigned = true,
            what = "field"
          } },
        is = "union",
        metaName = "TableResourceHandle",
        name = "tagHandle",
        offset = 12,
        size = 4,
        type = "TableResourceHandle",
        what = "field"
      } },
    is = "struct",
    metaName = "TagReference",
    name = "firstPersonAnimations",
    offset = 1132,
    size = 16,
    type = "TagReference",
    what = "field"
  }, {
    address = "0x47c",
    count = 4,
    elementSize = 1,
    elementType = "char",
    is = "array",
    name = "pad9662",
    offset = 1148,
    size = 4,
    what = "field"
  }, {
    address = "0x480",
    fields = { {
        address = "0x0",
        is = "int",
        metaName = "TagGroup",
        name = "tagGroup",
        offset = 0,
        size = 4,
        type = "int",
        what = "field"
      }, {
        address = "0x4",
        count = 4,
        elementSize = 1,
        elementType = "char",
        is = "ptr",
        name = "path",
        offset = 4,
        size = 4,
        what = "field"
      }, {
        address = "0x8",
        is = "int",
        name = "pathSize",
        offset = 8,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "field"
      }, {
        address = "0xc",
        fields = { {
            address = "0x0",
            is = "int",
            name = "value",
            offset = 0,
            size = 4,
            type = "dword",
            unsigned = true,
            what = "field"
          }, {
            address = "0x0",
            is = "int",
            name = "index",
            offset = 0,
            size = 2,
            type = "word",
            unsigned = true,
            what = "field"
          }, {
            address = "0x2",
            is = "int",
            name = "id",
            offset = 2,
            size = 2,
            type = "word",
            unsigned = true,
            what = "field"
          } },
        is = "union",
        metaName = "TableResourceHandle",
        name = "tagHandle",
        offset = 12,
        size = 4,
        type = "TableResourceHandle",
        what = "field"
      } },
    is = "struct",
    metaName = "TagReference",
    name = "hudInterface",
    offset = 1152,
    size = 16,
    type = "TagReference",
    what = "field"
  }, {
    address = "0x490",
    fields = { {
        address = "0x0",
        is = "int",
        metaName = "TagGroup",
        name = "tagGroup",
        offset = 0,
        size = 4,
        type = "int",
        what = "field"
      }, {
        address = "0x4",
        count = 4,
        elementSize = 1,
        elementType = "char",
        is = "ptr",
        name = "path",
        offset = 4,
        size = 4,
        what = "field"
      }, {
        address = "0x8",
        is = "int",
        name = "pathSize",
        offset = 8,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "field"
      }, {
        address = "0xc",
        fields = { {
            address = "0x0",
            is = "int",
            name = "value",
            offset = 0,
            size = 4,
            type = "dword",
            unsigned = true,
            what = "field"
          }, {
            address = "0x0",
            is = "int",
            name = "index",
            offset = 0,
            size = 2,
            type = "word",
            unsigned = true,
            what = "field"
          }, {
            address = "0x2",
            is = "int",
            name = "id",
            offset = 2,
            size = 2,
            type = "word",
            unsigned = true,
            what = "field"
          } },
        is = "union",
        metaName = "TableResourceHandle",
        name = "tagHandle",
        offset = 12,
        size = 4,
        type = "TableResourceHandle",
        what = "field"
      } },
    is = "struct",
    metaName = "TagReference",
    name = "pickupSound",
    offset = 1168,
    size = 16,
    type = "TagReference",
    what = "field"
  }, {
    address = "0x4a0",
    fields = { {
        address = "0x0",
        is = "int",
        metaName = "TagGroup",
        name = "tagGroup",
        offset = 0,
        size = 4,
        type = "int",
        what = "field"
      }, {
        address = "0x4",
        count = 4,
        elementSize = 1,
        elementType = "char",
        is = "ptr",
        name = "path",
        offset = 4,
        size = 4,
        what = "field"
      }, {
        address = "0x8",
        is = "int",
        name = "pathSize",
        offset = 8,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "field"
      }, {
        address = "0xc",
        fields = { {
            address = "0x0",
            is = "int",
            name = "value",
            offset = 0,
            size = 4,
            type = "dword",
            unsigned = true,
            what = "field"
          }, {
            address = "0x0",
            is = "int",
            name = "index",
            offset = 0,
            size = 2,
            type = "word",
            unsigned = true,
            what = "field"
          }, {
            address = "0x2",
            is = "int",
            name = "id",
            offset = 2,
            size = 2,
            type = "word",
            unsigned = true,
            what = "field"
          } },
        is = "union",
        metaName = "TableResourceHandle",
        name = "tagHandle",
        offset = 12,
        size = 4,
        type = "TableResourceHandle",
        what = "field"
      } },
    is = "struct",
    metaName = "TagReference",
    name = "zoomInSound",
    offset = 1184,
    size = 16,
    type = "TagReference",
    what = "field"
  }, {
    address = "0x4b0",
    fields = { {
        address = "0x0",
        is = "int",
        metaName = "TagGroup",
        name = "tagGroup",
        offset = 0,
        size = 4,
        type = "int",
        what = "field"
      }, {
        address = "0x4",
        count = 4,
        elementSize = 1,
        elementType = "char",
        is = "ptr",
        name = "path",
        offset = 4,
        size = 4,
        what = "field"
      }, {
        address = "0x8",
        is = "int",
        name = "pathSize",
        offset = 8,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "field"
      }, {
        address = "0xc",
        fields = { {
            address = "0x0",
            is = "int",
            name = "value",
            offset = 0,
            size = 4,
            type = "dword",
            unsigned = true,
            what = "field"
          }, {
            address = "0x0",
            is = "int",
            name = "index",
            offset = 0,
            size = 2,
            type = "word",
            unsigned = true,
            what = "field"
          }, {
            address = "0x2",
            is = "int",
            name = "id",
            offset = 2,
            size = 2,
            type = "word",
            unsigned = true,
            what = "field"
          } },
        is = "union",
        metaName = "TableResourceHandle",
        name = "tagHandle",
        offset = 12,
        size = 4,
        type = "TableResourceHandle",
        what = "field"
      } },
    is = "struct",
    metaName = "TagReference",
    name = "zoomOutSound",
    offset = 1200,
    size = 16,
    type = "TagReference",
    what = "field"
  }, {
    address = "0x4c0",
    count = 12,
    elementSize = 1,
    elementType = "char",
    is = "array",
    name = "pad9812",
    offset = 1216,
    size = 12,
    what = "field"
  }, {
    address = "0x4cc",
    is = "float",
    name = "activeCamoDing",
    offset = 1228,
    size = 4,
    type = "float",
    what = "field"
  }, {
    address = "0x4d0",
    is = "float",
    name = "activeCamoRegrowthRate",
    offset = 1232,
    size = 4,
    type = "float",
    what = "field"
  }, {
    address = "0x4d4",
    count = 12,
    elementSize = 1,
    elementType = "char",
    is = "array",
    name = "pad9900",
    offset = 1236,
    size = 12,
    what = "field"
  }, {
    address = "0x4e0",
    count = 2,
    elementSize = 1,
    elementType = "char",
    is = "array",
    name = "pad9923",
    offset = 1248,
    size = 2,
    what = "field"
  }, {
    address = "0x4e2",
    is = "int",
    metaName = "WeaponType",
    name = "weaponType",
    offset = 1250,
    size = 2,
    type = "short",
    what = "field"
  }, {
    address = "0x4e4",
    fields = { {
        address = "0x0",
        is = "int",
        name = "count",
        offset = 0,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "field"
      }, {
        address = "0x4",
        count = 0,
        elementSize = 8,
        fields = { {
            address = "0x0",
            is = "int",
            metaName = "PredictedResourceType",
            name = "type",
            offset = 0,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0x2",
            is = "int",
            name = "resourceIndex",
            offset = 2,
            size = 2,
            type = "word",
            unsigned = true,
            what = "field"
          }, {
            address = "0x4",
            fields = { {
                address = "0x0",
                is = "int",
                name = "value",
                offset = 0,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "field"
              }, {
                address = "0x0",
                is = "int",
                name = "index",
                offset = 0,
                size = 2,
                type = "word",
                unsigned = true,
                what = "field"
              }, {
                address = "0x2",
                is = "int",
                name = "id",
                offset = 2,
                size = 2,
                type = "word",
                unsigned = true,
                what = "field"
              } },
            is = "union",
            metaName = "TableResourceHandle",
            name = "tag",
            offset = 4,
            size = 4,
            type = "TableResourceHandle",
            what = "field"
          } },
        is = "ptr",
        name = "elements",
        offset = 4,
        size = 4,
        what = "field"
      }, {
        address = "0x8",
        count = 0,
        elementSize = 20,
        fields = { {
            address = "0x0",
            count = 4,
            elementSize = 1,
            elementType = "char",
            is = "ptr",
            name = "name",
            offset = 0,
            size = 4,
            what = "field"
          }, {
            address = "0x4",
            is = "int",
            name = "maximum",
            offset = 4,
            size = 4,
            type = "int",
            what = "field"
          }, {
            address = "0x8",
            count = 4,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "padding",
            offset = 8,
            size = 4,
            what = "field"
          }, {
            address = "0xc",
            is = "int",
            name = "elementsSize",
            offset = 12,
            size = 4,
            type = "int",
            what = "field"
          }, {
            address = "0x10",
            count = 0,
            elementSize = "none",
            elementType = "void",
            is = "ptr",
            name = "fields",
            offset = 16,
            size = 4,
            what = "field"
          } },
        is = "ptr",
        name = "definition",
        offset = 8,
        size = 4,
        what = "field"
      } },
    is = "struct",
    name = "morePredictedResources",
    offset = 1252,
    size = 12,
    what = "field"
  }, {
    address = "0x4f0",
    fields = { {
        address = "0x0",
        is = "int",
        name = "count",
        offset = 0,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "field"
      }, {
        address = "0x4",
        count = 0,
        elementSize = 112,
        fields = { {
            address = "0x0",
            fields = { {
                address = "0x0",
                is = "int",
                name = "wastesRoundsWhenReloaded",
                offset = 0,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "bitfield"
              }, {
                address = "0x0",
                is = "int",
                name = "everyRoundMustBeChambered",
                offset = 1,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "bitfield"
              } },
            is = "struct",
            metaName = "WeaponMagazineFlags",
            name = "flags",
            offset = 0,
            size = 4,
            type = "WeaponMagazineFlags",
            what = "field"
          }, {
            address = "0x4",
            is = "int",
            name = "roundsRecharged",
            offset = 4,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0x6",
            is = "int",
            name = "roundsTotalInitial",
            offset = 6,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0x8",
            is = "int",
            name = "roundsReservedMaximum",
            offset = 8,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0xa",
            is = "int",
            name = "roundsLoadedMaximum",
            offset = 10,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0xc",
            count = 8,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad5373",
            offset = 12,
            size = 8,
            what = "field"
          }, {
            address = "0x14",
            is = "float",
            name = "reloadTime",
            offset = 20,
            size = 4,
            type = "float",
            what = "field"
          }, {
            address = "0x18",
            is = "int",
            name = "roundsReloaded",
            offset = 24,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0x1a",
            count = 2,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad5447",
            offset = 26,
            size = 2,
            what = "field"
          }, {
            address = "0x1c",
            is = "float",
            name = "chamberTime",
            offset = 28,
            size = 4,
            type = "float",
            what = "field"
          }, {
            address = "0x20",
            count = 8,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad5493",
            offset = 32,
            size = 8,
            what = "field"
          }, {
            address = "0x28",
            count = 16,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad5515",
            offset = 40,
            size = 16,
            what = "field"
          }, {
            address = "0x38",
            fields = { {
                address = "0x0",
                is = "int",
                metaName = "TagGroup",
                name = "tagGroup",
                offset = 0,
                size = 4,
                type = "int",
                what = "field"
              }, {
                address = "0x4",
                count = 4,
                elementSize = 1,
                elementType = "char",
                is = "ptr",
                name = "path",
                offset = 4,
                size = 4,
                what = "field"
              }, {
                address = "0x8",
                is = "int",
                name = "pathSize",
                offset = 8,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "field"
              }, {
                address = "0xc",
                fields = { {
                    address = "0x0",
                    is = "int",
                    name = "value",
                    offset = 0,
                    size = 4,
                    type = "dword",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x0",
                    is = "int",
                    name = "index",
                    offset = 0,
                    size = 2,
                    type = "word",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x2",
                    is = "int",
                    name = "id",
                    offset = 2,
                    size = 2,
                    type = "word",
                    unsigned = true,
                    what = "field"
                  } },
                is = "union",
                metaName = "TableResourceHandle",
                name = "tagHandle",
                offset = 12,
                size = 4,
                type = "TableResourceHandle",
                what = "field"
              } },
            is = "struct",
            metaName = "TagReference",
            name = "reloadingEffect",
            offset = 56,
            size = 16,
            type = "TagReference",
            what = "field"
          }, {
            address = "0x48",
            fields = { {
                address = "0x0",
                is = "int",
                metaName = "TagGroup",
                name = "tagGroup",
                offset = 0,
                size = 4,
                type = "int",
                what = "field"
              }, {
                address = "0x4",
                count = 4,
                elementSize = 1,
                elementType = "char",
                is = "ptr",
                name = "path",
                offset = 4,
                size = 4,
                what = "field"
              }, {
                address = "0x8",
                is = "int",
                name = "pathSize",
                offset = 8,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "field"
              }, {
                address = "0xc",
                fields = { {
                    address = "0x0",
                    is = "int",
                    name = "value",
                    offset = 0,
                    size = 4,
                    type = "dword",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x0",
                    is = "int",
                    name = "index",
                    offset = 0,
                    size = 2,
                    type = "word",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x2",
                    is = "int",
                    name = "id",
                    offset = 2,
                    size = 2,
                    type = "word",
                    unsigned = true,
                    what = "field"
                  } },
                is = "union",
                metaName = "TableResourceHandle",
                name = "tagHandle",
                offset = 12,
                size = 4,
                type = "TableResourceHandle",
                what = "field"
              } },
            is = "struct",
            metaName = "TagReference",
            name = "chamberingEffect",
            offset = 72,
            size = 16,
            type = "TagReference",
            what = "field"
          }, {
            address = "0x58",
            count = 12,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad5609",
            offset = 88,
            size = 12,
            what = "field"
          }, {
            address = "0x64",
            fields = { {
                address = "0x0",
                is = "int",
                name = "count",
                offset = 0,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "field"
              }, {
                address = "0x4",
                count = 0,
                elementSize = 28,
                fields = { {
                    address = "0x0",
                    is = "int",
                    name = "rounds",
                    offset = 0,
                    size = 2,
                    type = "short",
                    what = "field"
                  }, {
                    address = "0x2",
                    count = 10,
                    elementSize = 1,
                    elementType = "char",
                    is = "array",
                    name = "pad5045",
                    offset = 2,
                    size = 10,
                    what = "field"
                  }, {
                    address = "0xc",
                    fields = { {
                        address = "0x0",
                        is = "int",
                        metaName = "TagGroup",
                        name = "tagGroup",
                        offset = 0,
                        size = 4,
                        type = "int",
                        what = "field"
                      }, {
                        address = "0x4",
                        count = 4,
                        elementSize = 1,
                        elementType = "char",
                        is = "ptr",
                        name = "path",
                        offset = 4,
                        size = 4,
                        what = "field"
                      }, {
                        address = "0x8",
                        is = "int",
                        name = "pathSize",
                        offset = 8,
                        size = 4,
                        type = "dword",
                        unsigned = true,
                        what = "field"
                      }, {
                        address = "0xc",
                        fields = { {
                            address = "0x0",
                            is = "int",
                            name = "value",
                            offset = 0,
                            size = 4,
                            type = "dword",
                            unsigned = true,
                            what = "field"
                          }, {
                            address = "0x0",
                            is = "int",
                            name = "index",
                            offset = 0,
                            size = 2,
                            type = "word",
                            unsigned = true,
                            what = "field"
                          }, {
                            address = "0x2",
                            is = "int",
                            name = "id",
                            offset = 2,
                            size = 2,
                            type = "word",
                            unsigned = true,
                            what = "field"
                          } },
                        is = "union",
                        metaName = "TableResourceHandle",
                        name = "tagHandle",
                        offset = 12,
                        size = 4,
                        type = "TableResourceHandle",
                        what = "field"
                      } },
                    is = "struct",
                    metaName = "TagReference",
                    name = "equipment",
                    offset = 12,
                    size = 16,
                    type = "TagReference",
                    what = "field"
                  } },
                is = "ptr",
                name = "elements",
                offset = 4,
                size = 4,
                what = "field"
              }, {
                address = "0x8",
                count = 0,
                elementSize = 20,
                fields = { {
                    address = "0x0",
                    count = 4,
                    elementSize = 1,
                    elementType = "char",
                    is = "ptr",
                    name = "name",
                    offset = 0,
                    size = 4,
                    what = "field"
                  }, {
                    address = "0x4",
                    is = "int",
                    name = "maximum",
                    offset = 4,
                    size = 4,
                    type = "int",
                    what = "field"
                  }, {
                    address = "0x8",
                    count = 4,
                    elementSize = 1,
                    elementType = "char",
                    is = "array",
                    name = "padding",
                    offset = 8,
                    size = 4,
                    what = "field"
                  }, {
                    address = "0xc",
                    is = "int",
                    name = "elementsSize",
                    offset = 12,
                    size = 4,
                    type = "int",
                    what = "field"
                  }, {
                    address = "0x10",
                    count = 0,
                    elementSize = "none",
                    elementType = "void",
                    is = "ptr",
                    name = "fields",
                    offset = 16,
                    size = 4,
                    what = "field"
                  } },
                is = "ptr",
                name = "definition",
                offset = 8,
                size = 4,
                what = "field"
              } },
            is = "struct",
            name = "magazineObjects",
            offset = 100,
            size = 12,
            what = "field"
          } },
        is = "ptr",
        name = "elements",
        offset = 4,
        size = 4,
        what = "field"
      }, {
        address = "0x8",
        count = 0,
        elementSize = 20,
        fields = { {
            address = "0x0",
            count = 4,
            elementSize = 1,
            elementType = "char",
            is = "ptr",
            name = "name",
            offset = 0,
            size = 4,
            what = "field"
          }, {
            address = "0x4",
            is = "int",
            name = "maximum",
            offset = 4,
            size = 4,
            type = "int",
            what = "field"
          }, {
            address = "0x8",
            count = 4,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "padding",
            offset = 8,
            size = 4,
            what = "field"
          }, {
            address = "0xc",
            is = "int",
            name = "elementsSize",
            offset = 12,
            size = 4,
            type = "int",
            what = "field"
          }, {
            address = "0x10",
            count = 0,
            elementSize = "none",
            elementType = "void",
            is = "ptr",
            name = "fields",
            offset = 16,
            size = 4,
            what = "field"
          } },
        is = "ptr",
        name = "definition",
        offset = 8,
        size = 4,
        what = "field"
      } },
    is = "struct",
    name = "magazines",
    offset = 1264,
    size = 12,
    what = "field"
  }, {
    address = "0x4fc",
    fields = { {
        address = "0x0",
        is = "int",
        name = "count",
        offset = 0,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "field"
      }, {
        address = "0x4",
        count = 0,
        elementSize = 276,
        fields = { {
            address = "0x0",
            fields = { {
                address = "0x0",
                is = "int",
                name = "tracksFiredProjectile",
                offset = 0,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "bitfield"
              }, {
                address = "0x0",
                is = "int",
                name = "randomFiringEffects",
                offset = 1,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "bitfield"
              }, {
                address = "0x0",
                is = "int",
                name = "canFireWithPartialAmmo",
                offset = 2,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "bitfield"
              }, {
                address = "0x0",
                is = "int",
                name = "doesNotRepeatAutomatically",
                offset = 3,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "bitfield"
              }, {
                address = "0x0",
                is = "int",
                name = "locksInOnOffState",
                offset = 4,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "bitfield"
              }, {
                address = "0x0",
                is = "int",
                name = "projectilesUseWeaponOrigin",
                offset = 5,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "bitfield"
              }, {
                address = "0x0",
                is = "int",
                name = "sticksWhenDropped",
                offset = 6,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "bitfield"
              }, {
                address = "0x0",
                is = "int",
                name = "ejectsDuringChamber",
                offset = 7,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "bitfield"
              }, {
                address = "0x1",
                is = "int",
                name = "dischargingSpews",
                offset = 8,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "bitfield"
              }, {
                address = "0x1",
                is = "int",
                name = "analogRateOfFire",
                offset = 9,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "bitfield"
              }, {
                address = "0x1",
                is = "int",
                name = "useErrorWhenUnzoomed",
                offset = 10,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "bitfield"
              }, {
                address = "0x1",
                is = "int",
                name = "projectileVectorCannotBeAdjusted",
                offset = 11,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "bitfield"
              }, {
                address = "0x1",
                is = "int",
                name = "projectilesHaveIdenticalError",
                offset = 12,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "bitfield"
              }, {
                address = "0x1",
                is = "int",
                name = "projectileIsClientSideOnly",
                offset = 13,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "bitfield"
              }, {
                address = "0x1",
                is = "int",
                name = "useOriginalUnitAdjustProjectileRay",
                offset = 14,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "bitfield"
              } },
            is = "struct",
            metaName = "WeaponTriggerFlags",
            name = "flags",
            offset = 0,
            size = 4,
            type = "WeaponTriggerFlags",
            what = "field"
          }, {
            address = "0x4",
            count = 2,
            elementSize = 4,
            elementType = "float",
            is = "array",
            name = "maximumRateOfFire",
            offset = 4,
            size = 8,
            what = "field"
          }, {
            address = "0xc",
            is = "float",
            name = "accelerationTime",
            offset = 12,
            size = 4,
            type = "float",
            what = "field"
          }, {
            address = "0x10",
            is = "float",
            name = "decelerationTime",
            offset = 16,
            size = 4,
            type = "float",
            what = "field"
          }, {
            address = "0x14",
            is = "float",
            name = "blurredRateOfFire",
            offset = 20,
            size = 4,
            type = "float",
            what = "field"
          }, {
            address = "0x18",
            count = 8,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad6379",
            offset = 24,
            size = 8,
            what = "field"
          }, {
            address = "0x20",
            is = "int",
            name = "magazine",
            offset = 32,
            size = 2,
            type = "word",
            unsigned = true,
            what = "field"
          }, {
            address = "0x22",
            is = "int",
            name = "roundsPerShot",
            offset = 34,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0x24",
            is = "int",
            name = "minimumRoundsLoaded",
            offset = 36,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0x26",
            is = "int",
            name = "projectilesBetweenContrails",
            offset = 38,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0x28",
            count = 4,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad6531",
            offset = 40,
            size = 4,
            what = "field"
          }, {
            address = "0x2c",
            is = "int",
            metaName = "WeaponPredictionType",
            name = "predictionType",
            offset = 44,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0x2e",
            is = "int",
            metaName = "ObjectNoise",
            name = "firingNoise",
            offset = 46,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0x30",
            count = 2,
            elementSize = 4,
            elementType = "float",
            is = "array",
            name = "error",
            offset = 48,
            size = 8,
            what = "field"
          }, {
            address = "0x38",
            is = "float",
            name = "errorAccelerationTime",
            offset = 56,
            size = 4,
            type = "float",
            what = "field"
          }, {
            address = "0x3c",
            is = "float",
            name = "errorDecelerationTime",
            offset = 60,
            size = 4,
            type = "float",
            what = "field"
          }, {
            address = "0x40",
            count = 8,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad6715",
            offset = 64,
            size = 8,
            what = "field"
          }, {
            address = "0x48",
            is = "float",
            name = "chargingTime",
            offset = 72,
            size = 4,
            type = "float",
            what = "field"
          }, {
            address = "0x4c",
            is = "float",
            name = "chargedTime",
            offset = 76,
            size = 4,
            type = "float",
            what = "field"
          }, {
            address = "0x50",
            is = "int",
            metaName = "WeaponOverchargedAction",
            name = "overchargedAction",
            offset = 80,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0x52",
            count = 2,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad6834",
            offset = 82,
            size = 2,
            what = "field"
          }, {
            address = "0x54",
            is = "float",
            name = "chargedIllumination",
            offset = 84,
            size = 4,
            type = "float",
            what = "field"
          }, {
            address = "0x58",
            is = "float",
            name = "spewTime",
            offset = 88,
            size = 4,
            type = "float",
            what = "field"
          }, {
            address = "0x5c",
            fields = { {
                address = "0x0",
                is = "int",
                metaName = "TagGroup",
                name = "tagGroup",
                offset = 0,
                size = 4,
                type = "int",
                what = "field"
              }, {
                address = "0x4",
                count = 4,
                elementSize = 1,
                elementType = "char",
                is = "ptr",
                name = "path",
                offset = 4,
                size = 4,
                what = "field"
              }, {
                address = "0x8",
                is = "int",
                name = "pathSize",
                offset = 8,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "field"
              }, {
                address = "0xc",
                fields = { {
                    address = "0x0",
                    is = "int",
                    name = "value",
                    offset = 0,
                    size = 4,
                    type = "dword",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x0",
                    is = "int",
                    name = "index",
                    offset = 0,
                    size = 2,
                    type = "word",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x2",
                    is = "int",
                    name = "id",
                    offset = 2,
                    size = 2,
                    type = "word",
                    unsigned = true,
                    what = "field"
                  } },
                is = "union",
                metaName = "TableResourceHandle",
                name = "tagHandle",
                offset = 12,
                size = 4,
                type = "TableResourceHandle",
                what = "field"
              } },
            is = "struct",
            metaName = "TagReference",
            name = "chargingEffect",
            offset = 92,
            size = 16,
            type = "TagReference",
            what = "field"
          }, {
            address = "0x6c",
            is = "int",
            metaName = "WeaponDistributionFunction",
            name = "distributionFunction",
            offset = 108,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0x6e",
            is = "int",
            name = "projectilesPerShot",
            offset = 110,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0x70",
            is = "float",
            name = "distributionAngle",
            offset = 112,
            size = 4,
            type = "float",
            what = "field"
          }, {
            address = "0x74",
            count = 4,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad7061",
            offset = 116,
            size = 4,
            what = "field"
          }, {
            address = "0x78",
            is = "float",
            name = "minimumError",
            offset = 120,
            size = 4,
            type = "float",
            what = "field"
          }, {
            address = "0x7c",
            count = 2,
            elementSize = 4,
            elementType = "float",
            is = "array",
            name = "errorAngle",
            offset = 124,
            size = 8,
            what = "field"
          }, {
            address = "0x84",
            fields = { {
                address = "0x0",
                is = "float",
                name = "x",
                offset = 0,
                size = 4,
                type = "float",
                what = "field"
              }, {
                address = "0x4",
                is = "float",
                name = "y",
                offset = 4,
                size = 4,
                type = "float",
                what = "field"
              }, {
                address = "0x8",
                is = "float",
                name = "z",
                offset = 8,
                size = 4,
                type = "float",
                what = "field"
              } },
            is = "struct",
            metaName = "VectorXYZ",
            name = "firstPersonOffset",
            offset = 132,
            size = 12,
            type = "VectorXYZ",
            what = "field"
          }, {
            address = "0x90",
            count = 4,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad7169",
            offset = 144,
            size = 4,
            what = "field"
          }, {
            address = "0x94",
            fields = { {
                address = "0x0",
                is = "int",
                metaName = "TagGroup",
                name = "tagGroup",
                offset = 0,
                size = 4,
                type = "int",
                what = "field"
              }, {
                address = "0x4",
                count = 4,
                elementSize = 1,
                elementType = "char",
                is = "ptr",
                name = "path",
                offset = 4,
                size = 4,
                what = "field"
              }, {
                address = "0x8",
                is = "int",
                name = "pathSize",
                offset = 8,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "field"
              }, {
                address = "0xc",
                fields = { {
                    address = "0x0",
                    is = "int",
                    name = "value",
                    offset = 0,
                    size = 4,
                    type = "dword",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x0",
                    is = "int",
                    name = "index",
                    offset = 0,
                    size = 2,
                    type = "word",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x2",
                    is = "int",
                    name = "id",
                    offset = 2,
                    size = 2,
                    type = "word",
                    unsigned = true,
                    what = "field"
                  } },
                is = "union",
                metaName = "TableResourceHandle",
                name = "tagHandle",
                offset = 12,
                size = 4,
                type = "TableResourceHandle",
                what = "field"
              } },
            is = "struct",
            metaName = "TagReference",
            name = "projectile",
            offset = 148,
            size = 16,
            type = "TagReference",
            what = "field"
          }, {
            address = "0xa4",
            is = "float",
            name = "ejectionPortRecoveryTime",
            offset = 164,
            size = 4,
            type = "float",
            what = "field"
          }, {
            address = "0xa8",
            is = "float",
            name = "illuminationRecoveryTime",
            offset = 168,
            size = 4,
            type = "float",
            what = "field"
          }, {
            address = "0xac",
            count = 12,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad7297",
            offset = 172,
            size = 12,
            what = "field"
          }, {
            address = "0xb8",
            is = "float",
            name = "heatGeneratedPerRound",
            offset = 184,
            size = 4,
            type = "float",
            what = "field"
          }, {
            address = "0xbc",
            is = "float",
            name = "ageGeneratedPerRound",
            offset = 188,
            size = 4,
            type = "float",
            what = "field"
          }, {
            address = "0xc0",
            count = 4,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad7391",
            offset = 192,
            size = 4,
            what = "field"
          }, {
            address = "0xc4",
            is = "float",
            name = "overloadTime",
            offset = 196,
            size = 4,
            type = "float",
            what = "field"
          }, {
            address = "0xc8",
            count = 8,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad7438",
            offset = 200,
            size = 8,
            what = "field"
          }, {
            address = "0xd0",
            count = 32,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad7460",
            offset = 208,
            size = 32,
            what = "field"
          }, {
            address = "0xf0",
            is = "float",
            name = "illuminationRecoveryRate",
            offset = 240,
            size = 4,
            type = "float",
            what = "field"
          }, {
            address = "0xf4",
            is = "float",
            name = "ejectionPortRecoveryRate",
            offset = 244,
            size = 4,
            type = "float",
            what = "field"
          }, {
            address = "0xf8",
            is = "float",
            name = "firingAccelerationRate",
            offset = 248,
            size = 4,
            type = "float",
            what = "field"
          }, {
            address = "0xfc",
            is = "float",
            name = "firingDecelerationRate",
            offset = 252,
            size = 4,
            type = "float",
            what = "field"
          }, {
            address = "0x100",
            is = "float",
            name = "errorAccelerationRate",
            offset = 256,
            size = 4,
            type = "float",
            what = "field"
          }, {
            address = "0x104",
            is = "float",
            name = "errorDecelerationRate",
            offset = 260,
            size = 4,
            type = "float",
            what = "field"
          }, {
            address = "0x108",
            fields = { {
                address = "0x0",
                is = "int",
                name = "count",
                offset = 0,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "field"
              }, {
                address = "0x4",
                count = 0,
                elementSize = 132,
                fields = { {
                    address = "0x0",
                    count = 2,
                    elementSize = 2,
                    elementType = "short",
                    is = "array",
                    name = "shotCount",
                    offset = 0,
                    size = 4,
                    what = "field"
                  }, {
                    address = "0x4",
                    count = 32,
                    elementSize = 1,
                    elementType = "char",
                    is = "array",
                    name = "pad5889",
                    offset = 4,
                    size = 32,
                    what = "field"
                  }, {
                    address = "0x24",
                    fields = { {
                        address = "0x0",
                        is = "int",
                        metaName = "TagGroup",
                        name = "tagGroup",
                        offset = 0,
                        size = 4,
                        type = "int",
                        what = "field"
                      }, {
                        address = "0x4",
                        count = 4,
                        elementSize = 1,
                        elementType = "char",
                        is = "ptr",
                        name = "path",
                        offset = 4,
                        size = 4,
                        what = "field"
                      }, {
                        address = "0x8",
                        is = "int",
                        name = "pathSize",
                        offset = 8,
                        size = 4,
                        type = "dword",
                        unsigned = true,
                        what = "field"
                      }, {
                        address = "0xc",
                        fields = { {
                            address = "0x0",
                            is = "int",
                            name = "value",
                            offset = 0,
                            size = 4,
                            type = "dword",
                            unsigned = true,
                            what = "field"
                          }, {
                            address = "0x0",
                            is = "int",
                            name = "index",
                            offset = 0,
                            size = 2,
                            type = "word",
                            unsigned = true,
                            what = "field"
                          }, {
                            address = "0x2",
                            is = "int",
                            name = "id",
                            offset = 2,
                            size = 2,
                            type = "word",
                            unsigned = true,
                            what = "field"
                          } },
                        is = "union",
                        metaName = "TableResourceHandle",
                        name = "tagHandle",
                        offset = 12,
                        size = 4,
                        type = "TableResourceHandle",
                        what = "field"
                      } },
                    is = "struct",
                    metaName = "TagReference",
                    name = "firingEffect",
                    offset = 36,
                    size = 16,
                    type = "TagReference",
                    what = "field"
                  }, {
                    address = "0x34",
                    fields = { {
                        address = "0x0",
                        is = "int",
                        metaName = "TagGroup",
                        name = "tagGroup",
                        offset = 0,
                        size = 4,
                        type = "int",
                        what = "field"
                      }, {
                        address = "0x4",
                        count = 4,
                        elementSize = 1,
                        elementType = "char",
                        is = "ptr",
                        name = "path",
                        offset = 4,
                        size = 4,
                        what = "field"
                      }, {
                        address = "0x8",
                        is = "int",
                        name = "pathSize",
                        offset = 8,
                        size = 4,
                        type = "dword",
                        unsigned = true,
                        what = "field"
                      }, {
                        address = "0xc",
                        fields = { {
                            address = "0x0",
                            is = "int",
                            name = "value",
                            offset = 0,
                            size = 4,
                            type = "dword",
                            unsigned = true,
                            what = "field"
                          }, {
                            address = "0x0",
                            is = "int",
                            name = "index",
                            offset = 0,
                            size = 2,
                            type = "word",
                            unsigned = true,
                            what = "field"
                          }, {
                            address = "0x2",
                            is = "int",
                            name = "id",
                            offset = 2,
                            size = 2,
                            type = "word",
                            unsigned = true,
                            what = "field"
                          } },
                        is = "union",
                        metaName = "TableResourceHandle",
                        name = "tagHandle",
                        offset = 12,
                        size = 4,
                        type = "TableResourceHandle",
                        what = "field"
                      } },
                    is = "struct",
                    metaName = "TagReference",
                    name = "misfireEffect",
                    offset = 52,
                    size = 16,
                    type = "TagReference",
                    what = "field"
                  }, {
                    address = "0x44",
                    fields = { {
                        address = "0x0",
                        is = "int",
                        metaName = "TagGroup",
                        name = "tagGroup",
                        offset = 0,
                        size = 4,
                        type = "int",
                        what = "field"
                      }, {
                        address = "0x4",
                        count = 4,
                        elementSize = 1,
                        elementType = "char",
                        is = "ptr",
                        name = "path",
                        offset = 4,
                        size = 4,
                        what = "field"
                      }, {
                        address = "0x8",
                        is = "int",
                        name = "pathSize",
                        offset = 8,
                        size = 4,
                        type = "dword",
                        unsigned = true,
                        what = "field"
                      }, {
                        address = "0xc",
                        fields = { {
                            address = "0x0",
                            is = "int",
                            name = "value",
                            offset = 0,
                            size = 4,
                            type = "dword",
                            unsigned = true,
                            what = "field"
                          }, {
                            address = "0x0",
                            is = "int",
                            name = "index",
                            offset = 0,
                            size = 2,
                            type = "word",
                            unsigned = true,
                            what = "field"
                          }, {
                            address = "0x2",
                            is = "int",
                            name = "id",
                            offset = 2,
                            size = 2,
                            type = "word",
                            unsigned = true,
                            what = "field"
                          } },
                        is = "union",
                        metaName = "TableResourceHandle",
                        name = "tagHandle",
                        offset = 12,
                        size = 4,
                        type = "TableResourceHandle",
                        what = "field"
                      } },
                    is = "struct",
                    metaName = "TagReference",
                    name = "emptyEffect",
                    offset = 68,
                    size = 16,
                    type = "TagReference",
                    what = "field"
                  }, {
                    address = "0x54",
                    fields = { {
                        address = "0x0",
                        is = "int",
                        metaName = "TagGroup",
                        name = "tagGroup",
                        offset = 0,
                        size = 4,
                        type = "int",
                        what = "field"
                      }, {
                        address = "0x4",
                        count = 4,
                        elementSize = 1,
                        elementType = "char",
                        is = "ptr",
                        name = "path",
                        offset = 4,
                        size = 4,
                        what = "field"
                      }, {
                        address = "0x8",
                        is = "int",
                        name = "pathSize",
                        offset = 8,
                        size = 4,
                        type = "dword",
                        unsigned = true,
                        what = "field"
                      }, {
                        address = "0xc",
                        fields = { {
                            address = "0x0",
                            is = "int",
                            name = "value",
                            offset = 0,
                            size = 4,
                            type = "dword",
                            unsigned = true,
                            what = "field"
                          }, {
                            address = "0x0",
                            is = "int",
                            name = "index",
                            offset = 0,
                            size = 2,
                            type = "word",
                            unsigned = true,
                            what = "field"
                          }, {
                            address = "0x2",
                            is = "int",
                            name = "id",
                            offset = 2,
                            size = 2,
                            type = "word",
                            unsigned = true,
                            what = "field"
                          } },
                        is = "union",
                        metaName = "TableResourceHandle",
                        name = "tagHandle",
                        offset = 12,
                        size = 4,
                        type = "TableResourceHandle",
                        what = "field"
                      } },
                    is = "struct",
                    metaName = "TagReference",
                    name = "firingDamage",
                    offset = 84,
                    size = 16,
                    type = "TagReference",
                    what = "field"
                  }, {
                    address = "0x64",
                    fields = { {
                        address = "0x0",
                        is = "int",
                        metaName = "TagGroup",
                        name = "tagGroup",
                        offset = 0,
                        size = 4,
                        type = "int",
                        what = "field"
                      }, {
                        address = "0x4",
                        count = 4,
                        elementSize = 1,
                        elementType = "char",
                        is = "ptr",
                        name = "path",
                        offset = 4,
                        size = 4,
                        what = "field"
                      }, {
                        address = "0x8",
                        is = "int",
                        name = "pathSize",
                        offset = 8,
                        size = 4,
                        type = "dword",
                        unsigned = true,
                        what = "field"
                      }, {
                        address = "0xc",
                        fields = { {
                            address = "0x0",
                            is = "int",
                            name = "value",
                            offset = 0,
                            size = 4,
                            type = "dword",
                            unsigned = true,
                            what = "field"
                          }, {
                            address = "0x0",
                            is = "int",
                            name = "index",
                            offset = 0,
                            size = 2,
                            type = "word",
                            unsigned = true,
                            what = "field"
                          }, {
                            address = "0x2",
                            is = "int",
                            name = "id",
                            offset = 2,
                            size = 2,
                            type = "word",
                            unsigned = true,
                            what = "field"
                          } },
                        is = "union",
                        metaName = "TableResourceHandle",
                        name = "tagHandle",
                        offset = 12,
                        size = 4,
                        type = "TableResourceHandle",
                        what = "field"
                      } },
                    is = "struct",
                    metaName = "TagReference",
                    name = "misfireDamage",
                    offset = 100,
                    size = 16,
                    type = "TagReference",
                    what = "field"
                  }, {
                    address = "0x74",
                    fields = { {
                        address = "0x0",
                        is = "int",
                        metaName = "TagGroup",
                        name = "tagGroup",
                        offset = 0,
                        size = 4,
                        type = "int",
                        what = "field"
                      }, {
                        address = "0x4",
                        count = 4,
                        elementSize = 1,
                        elementType = "char",
                        is = "ptr",
                        name = "path",
                        offset = 4,
                        size = 4,
                        what = "field"
                      }, {
                        address = "0x8",
                        is = "int",
                        name = "pathSize",
                        offset = 8,
                        size = 4,
                        type = "dword",
                        unsigned = true,
                        what = "field"
                      }, {
                        address = "0xc",
                        fields = { {
                            address = "0x0",
                            is = "int",
                            name = "value",
                            offset = 0,
                            size = 4,
                            type = "dword",
                            unsigned = true,
                            what = "field"
                          }, {
                            address = "0x0",
                            is = "int",
                            name = "index",
                            offset = 0,
                            size = 2,
                            type = "word",
                            unsigned = true,
                            what = "field"
                          }, {
                            address = "0x2",
                            is = "int",
                            name = "id",
                            offset = 2,
                            size = 2,
                            type = "word",
                            unsigned = true,
                            what = "field"
                          } },
                        is = "union",
                        metaName = "TableResourceHandle",
                        name = "tagHandle",
                        offset = 12,
                        size = 4,
                        type = "TableResourceHandle",
                        what = "field"
                      } },
                    is = "struct",
                    metaName = "TagReference",
                    name = "emptyDamage",
                    offset = 116,
                    size = 16,
                    type = "TagReference",
                    what = "field"
                  } },
                is = "ptr",
                name = "elements",
                offset = 4,
                size = 4,
                what = "field"
              }, {
                address = "0x8",
                count = 0,
                elementSize = 20,
                fields = { {
                    address = "0x0",
                    count = 4,
                    elementSize = 1,
                    elementType = "char",
                    is = "ptr",
                    name = "name",
                    offset = 0,
                    size = 4,
                    what = "field"
                  }, {
                    address = "0x4",
                    is = "int",
                    name = "maximum",
                    offset = 4,
                    size = 4,
                    type = "int",
                    what = "field"
                  }, {
                    address = "0x8",
                    count = 4,
                    elementSize = 1,
                    elementType = "char",
                    is = "array",
                    name = "padding",
                    offset = 8,
                    size = 4,
                    what = "field"
                  }, {
                    address = "0xc",
                    is = "int",
                    name = "elementsSize",
                    offset = 12,
                    size = 4,
                    type = "int",
                    what = "field"
                  }, {
                    address = "0x10",
                    count = 0,
                    elementSize = "none",
                    elementType = "void",
                    is = "ptr",
                    name = "fields",
                    offset = 16,
                    size = 4,
                    what = "field"
                  } },
                is = "ptr",
                name = "definition",
                offset = 8,
                size = 4,
                what = "field"
              } },
            is = "struct",
            name = "firingEffects",
            offset = 264,
            size = 12,
            what = "field"
          } },
        is = "ptr",
        name = "elements",
        offset = 4,
        size = 4,
        what = "field"
      }, {
        address = "0x8",
        count = 0,
        elementSize = 20,
        fields = { {
            address = "0x0",
            count = 4,
            elementSize = 1,
            elementType = "char",
            is = "ptr",
            name = "name",
            offset = 0,
            size = 4,
            what = "field"
          }, {
            address = "0x4",
            is = "int",
            name = "maximum",
            offset = 4,
            size = 4,
            type = "int",
            what = "field"
          }, {
            address = "0x8",
            count = 4,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "padding",
            offset = 8,
            size = 4,
            what = "field"
          }, {
            address = "0xc",
            is = "int",
            name = "elementsSize",
            offset = 12,
            size = 4,
            type = "int",
            what = "field"
          }, {
            address = "0x10",
            count = 0,
            elementSize = "none",
            elementType = "void",
            is = "ptr",
            name = "fields",
            offset = 16,
            size = 4,
            what = "field"
          } },
        is = "ptr",
        name = "definition",
        offset = 8,
        size = 4,
        what = "field"
      } },
    is = "struct",
    name = "triggers",
    offset = 1276,
    size = 12,
    what = "field"
  } }
