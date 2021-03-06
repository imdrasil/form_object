require "./abstract_form"

module FormObject
  # Base class for Jennifer form object.
  #
  # This class works only with Jennifer ORM.
  #
  # ```
  # class ContactForm < FormObject::Base(Contact)
  #   attr :name, String
  #   attr :sex, String, origin: :gender
  #   attr :count, Int32, virtual: true
  #   attr :_deleted, Bool?, virtual: true
  # end
  # ```
  #
  # FormObject::Base supports Jennifer validation DSL and API.
  #
  # ```
  # class ContactForm < FormObject::Base(Contact)
  #   # ...
  #   attr :count, Int32, virtual: true
  #
  #   validates_numericality :count, greater_than: 2
  # end
  #
  # c = Contact.new
  # f = ContactForm.new(c)
  # f.verify(request)
  # f.valid?
  # f.errors # Jennifer::Model::Errors
  # ```
  abstract class Base(T) < AbstractForm
    include Jennifer::Model::Validation

    def errors
      @errors ||= Jennifer::Model::Errors.new(resource)
    end

    getter resource : T

    def initialize(@resource)
      super()
    end

    def persist
      resource.save.tap do |state|
        next unless state
        persist_nested
      end
    end

    def persist_nested; end

    def self.human_attribute_name(attr)
      T.human_attribute_name(attr)
    end

    def self.all
      T.all
    end

    def new_record?
      resource.new_record?
    end

    def changed?
      resource.changed?
    end

    macro inherited
      # :nodoc:
      MAPPING = {} of Symbol => NamedTuple

      ::Jennifer::Model::Validation.inherited_hook

      # :nodoc:
      def self.superclass
        {{@type.superclass}}
      end

      macro finished
        mapping_finished_hook
        ::Jennifer::Model::Validation.finished_hook
      end
    end
  end
end
