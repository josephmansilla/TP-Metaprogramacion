
# =====================================
# ===== PUNTO 1: DSL e Impresión ======
# =====================================

module Document
  attr_accessor :alumno, :estado
  def initialize(alumno, estado)
    @alumno = alumno
    @estado = estado
  end
end

module Tag

end

# RESPETAR SINTAXIS como en la consigna.
# No es necesario preocuparse por el formateado del xml generado.
# self.msj(n1: p1,  n2: p2) do ... end
# msj n1: p1, n2: p2 { ... }
# son iguales

# ===========================================
# ===== PUNTO 2: Generación automática ======
# ===========================================

# El nombre del tag raíz debe ser el nombre de la clase de X, en minúsculas.

# Los atributos de X que no tengan definido un getter se ignoran.

# Los atributos de X con getter que referencian a Strings, Booleanos,
# Números o nil se deben serializar como atributos del tag raíz.

# Los atributos de X con getter que referencian a Arrays de objetos de cualquier tipo deben
# serializarse cómo tags hijos, conteniendo un nuevo tag hijo por cada elemento del array.
# Estos tags deben llamarse como la clase de los valores que representan.

# Los atributos de X con getter que referencian a cualquier otro tipo de objeto se deben
# serializar cómo tags hijos del tag raíz, cada uno con el nombre del atributo en cuestión.

module Alumno
  ✨Inline✨ {|campo| campo.downcase }
  attr_reader :nombre, :legajo, :estado
  def initialize(nombre, legajo, telefono, estado)
    @nombre = nombre
    @legajo = legajo
    @telefono = telefono
    @estado = estado
  end
end

class Estado
  attr_reader :finales_rendidos, :materias_aprobadas, :es_regular
  def initialize(finales, materias, es_regular)
    @finales_rendidos = finales
    @materias_aprobadas = materias
    @es_regular = es_regular
  end
end

unEstado = Estado.new(3, 5, true)
unAlumno = Alumno.new("Matias","123456-8", "1234567890", unEstado)

documento_manual = Document.new do
  alumno nombre: unAlumno.nombre, legajo: unAlumno.legajo do
    estado finales_rendidos: unAlumno.estado.finales_rendidos,
           materias_aprobadas: unAlumno.estado.materias_aprobadas,
           es_regular: unAlumno.estado.es_regular
  end
end

documento_automatico = Document.serialize(unAlumno)

documento_manual.xml == documento_automatico.xml  # Esto debe cumplirse


# NO repetir logica entre el punto 1 y 2.
# NO preocuparse por referencias cruzadas


# ================================================
# ===== PUNTO 3: Personalización y Metadata ======
# ================================================


# Si por utilizar un label algún XML quedara con dos atributos
# con el mismo nombre, el serializador debe fallar adecuadamente.
# No hay problema con tener múltiples hijos con el mismo nombre.

# ==================
# ===== Anexo ======
# ==================

class Tag
  attr_reader :label, :attributes, :children

  def self.with_label(label)
    new(label)
  end

  def initialize(label)
    @label = label
    @attributes = {}
    @children = []
  end

  def with_label(label)
    @label = label
    self
  end

  def with_attribute(label, value)
    @attributes[label] = value
    self
  end

  def with_child(child)
    @children << child
    self
  end

  def xml(level=0)
    if children.empty?
      "#{"\t" * level}<#{label}#{xml_attributes}/>"
    else
      "#{"\t" * level}<#{label}#{xml_attributes}>\n#{xml_children(level + 1)}\n#{"\t" * level}</#{label}>"
    end
  end

  private

  def xml_children(level)
    self.children.map do |child|
      if child.is_a? Tag
        child.xml(level)
      else
        xml_value(child, level)
      end
    end.join("\n")
  end

  def xml_attributes
    self.attributes.map do |name, value|
      "#{name}=#{xml_value(value, 0)}"
    end.xml_join(' ')
  end

  def xml_value(value, level)
    "\t" * level + if value.is_a? String
                     "\"#{value}\""
                   else
                     value.to_s
                   end
  end
end

class Array
  def xml_join(separator)
    self.join(separator).instance_eval do
      if !empty?
        "#{separator}#{self}"
      else
        self
      end
    end
  end
end


Tag
  .with_label('alumno')
  .with_attribute('nombre', 'Mati')
  .with_attribute('legajo', '123456-7')
  .with_attribute('edad', 27)
  .with_child(
    Tag
      .with_label('telefono')
      .with_child('12345678')
  )
  .with_child(
    Tag
      .with_label('estado')
      .with_child(
        Tag
          .with_label('value')
          .with_child('regular')
      )
  )
  .with_child(Tag.with_label('no_children'))
  .xml
