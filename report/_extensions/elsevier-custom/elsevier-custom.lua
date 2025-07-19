local kClassOpt = "classoption"

return {
  {
    Meta = function(meta)
      if quarto.doc.is_format("pdf") then
        -- Force double spacing for 3p model
        if meta.journal and meta.journal.model == "3p" then
          quarto.doc.include_text("in-header", "\\usepackage{setspace}\\doublespacing")
        end
        
        -- Ensure authoryear citation style works with review option
        if meta.journal and meta.journal.formatting == "review" then
          if meta.journal["cite-style"] == nil then
            meta.journal["cite-style"] = "authoryear"
          end
          if not meta[kClassOpt] then
            meta[kClassOpt] = pandoc.List()
          end
          meta[kClassOpt]:insert(pandoc.Str("authoryear"))
        end
      end
      return meta
    end
  }
}