package lexlogic.lexlogic.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "insurers")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Insurer {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String name;

    @Column(nullable = false)
    private String apiUrl;
}